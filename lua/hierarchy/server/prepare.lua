local utils = require('hierarchy.server.utils')

local symbol_map = {
  function_declaration = 12, -- Function
  class_definition = 5, -- Class
}

---@module 'hierarchy.server.annotations'

---Converts the treesitter type (obtained by `tsnode:type()`)
---
---@param tstype string type of a treesitter node
---@return lsp_symbol_kind|nil
local function tstype_to_lsp_symbol(tstype)
  -- Note: this function will not support every symbol
  return symbol_map[tstype]
end

---Local implementation of `textDocument/prepareTypeHierarchy`.
---
---Inside a method, returns an item for the method. Anywhere else inside
---a class, returns an item for the class.
---
---@param params lsp_params
---@return lsp_hierarchy_item[]|nil
local function prepare(params)
    local bufnr = vim.fn.bufadd(vim.uri_to_fname(params.textDocument.uri))
    local tree = utils.get_tree(bufnr)

    ---@type lsp_hierarchy_item
    local item = { uri = params.textDocument.uri }

    local node = tree:root():descendant_for_range(
      params.position.line,
      params.position.character,
      params.position.line,
      params.position.character + 1
    )

    local class = utils.first_parent_of_type(node, 'class_definition')
    local method = utils.first_parent_of_type(node, 'function_definition')

    if not class then
      return -- All supported cases require to be inside a class
    end

    item.kind = (method and 12) or 5

    -- Set the `selectionRange` enclosing the node
    local sr, sc, _ = class:start()
    local er, ec, _ = class:end_()
    item.range = {
      start = { line = sr, character = sc },
      ["end"] = { line = er, character = ec }
    }

    -- Set the range for the symbol's name & the name
    local name_node = (method or class):field("name")[1]
    local sr, sc, _ = name_node:start()
    local er, ec, _ = name_node:end_()
    item.selectionRange = {
      start = { line = sr, character = sc },
      ["end"] = { line = er, character = ec }
    }
    item.name = utils.get_node_text(name_node, bufnr)

    return {item}
end

return prepare
