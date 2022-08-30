local M = {}

local get_node_text = vim.treesitter.query.get_node_text
---Gets the text corresponding to a given node.
---  
---Documented wrapper around 'vim.treesitter.query.get_node_text'
---@see |get_node_text()|
---
---@param node tsnode
---@param bufnr integer
---@return string # text of the node
function M.get_node_text(node, bufnr)
  return vim.treesitter.query.get_node_text(node, bufnr)
end

---Queries the language for a given buffer
---
---@param bufnr integer number of the buffer
---@return string the language (filetype) for this buffer
function M.get_lang(bufnr)
  return vim.api.nvim_buf_get_option(bufnr or 0, 'filetype')
end


---Loads a treesitter tree for a given bufnr
---
---@param bufnr integer: number of the buffer to parse
---@return tsnode # the treesitter tree for this file
function M.get_tree(bufnr)
  vim.fn.bufload(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, M.get_lang(bufnr))
  return parser:parse()[1]
end


---Finds the node for a given LSP match in a buffer
---
---@param match lsp_location: match returned by an LSP request
---@param tree any
---@return tsnode
function M.node_from_match(match, tree)
  return tree:root():descendant_for_range(
    match.range.start.line,
    match.range.start.character,
    match.range["end"].line,
    match.range["end"].character
  )
end

---Returns a string representation for a `tsnode`
---
---@param node tsnode
---@param bufnr integer
---@return string
function M.log_node(node, bufnr)
  if not node then
    return "nil"
  end
  local sr, sc, _ = node:start()
  local er, ec, _ = node:end_()
  local name_node = node:field("name")[1]
  local name = (name_node and M.get_node_text(name_node, bufnr)) or "---"
  return name .. "(" .. sr .. "," .. sc .. ") (" .. er .. "," .. ec .. ")"
end


---Finds the first parent of the given tstype for a `tsnode`
---
---@param node tsnode
---@param tstype string
---@return tsnode|nil
function M.first_parent_of_type(node, tstype)
  local parent = node
  while parent and parent:type() ~= tstype do
    parent = parent:parent()
  end
  return parent
end

return M
