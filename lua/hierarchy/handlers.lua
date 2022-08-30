local M = {}


---Jumps to the first hierarchy item match, if any
---
---@param err any
---@param result lsp_hierarchy_item[]|nil
---@param ctx {params: {item: lsp_hierarchy_item}}
---@param config any
function M.jump_first(err, result, ctx, config)
  -- @TODO: find a way to choose the offset_encoding
  local item = result[1]
  if item then
    -- We prefer to jump at the selectionRange
    item.range = item.selectionRange
    vim.lsp.util.jump_to_location(item, 'utf-8')
  end
end


---Loads all matches to the quickfix list. Does not open the list.
---
---@param err any
---@param result lsp_hierarchy_item[]|nil
---@param ctx {params: {item: lsp_hierarchy_item}}
---@param config any
function M.load_quickfix(err, result, ctx, config)
  if not result then
    return
  end

  -- Insert the initial item queried as first element
  local items = result
  table.insert(items, 1, ctx.params.item)

  local utils = require('hierarchy.server.utils')

  local qf_items = {}
  for _, item in ipairs(items) do
    -- Create a quickfix list item
    qf_item = vim.lsp.util.symbols_to_items({item}, bufnr)[1]

    -- Prefix the class name for methods
    if ctx.params.item.kind == 12 then  -- Function
      local bufnr = vim.fn.bufadd(vim.uri_to_fname(item.uri))
      local tree = utils.get_tree(bufnr)

      local node = utils.node_from_match(item, tree)
      local class_name = utils.get_node_text(node:field("name")[1], bufnr)
      qf_item.text = qf_item.text:gsub(' ', ' ' .. class_name .. '.')
    end

    table.insert(qf_items, qf_item)
  end
  vim.fn.setqflist(qf_items, 'r')
end


---Loads all matches to the quickfix list, then opens the quickfix list.
---
---@param err any
---@param result lsp_hierarchy_item[]|nil
---@param ctx {params: {item: lsp_hierarchy_item}}
---@param config any
function M.quickfix(err, result, ctx, config)
  M.load_quickfix(err, result, ctx, config)
  vim.api.nvim_command('botright copen')
end


return M
