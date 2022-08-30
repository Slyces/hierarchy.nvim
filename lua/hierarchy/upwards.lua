ClassNode = RELOAD('heritage.class_node')
Searcher = RELOAD('heritage.search')

UpSearcher = Searcher:new()

UpSearcher.name = "UpSearcher"


---For a given node that matched this `searcher`'s LSP request, find a valid
---`classnode` if any.
---
---@param node tsnode
---@param bufnr integer
---@return classnode|nil
function UpSearcher:class_from_node(node, bufnr)
  -- For `upward` requests, we're using `textDocument/definition` requests. This
  -- means we're landing on the name of the class. It's safe to just find the
  -- nearest `class_definition` tsnode.
  local class = ClassNode:from_children(node, bufnr)
  return class
end


---Sends the next batch of requests for a given `classnode`.
---
---@param search_id string
---@param class classnode
function UpSearcher:send_requests(search_id, class)
  P("Called ↑")
  for _, parent in ipairs(class:direct_parents()) do
    local params = build_request(search_id, parent, class.bufnr)
    vim.lsp.buf_request(
      class.bufnr, 'textDocument/definition', params, self.handler
    )
  end
end


return UpSearcher
