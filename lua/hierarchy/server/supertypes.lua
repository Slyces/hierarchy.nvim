Searcher = RELOAD('hierarchy.server.search')
ClassNode = RELOAD('hierarchy.server.class_node')

Supertypes = Searcher:new()


---For a given node that matched this `searcher`'s LSP request, find a valid
---`classnode` if any.
---
---@param node tsnode
---@param bufnr integer
---@return classnode|nil
function Supertypes:class_from_node(node, bufnr)
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
function Supertypes:send_requests(search_id, class)
  for _, parent in ipairs(class:direct_parents()) do
    local params = self.build_params(search_id, parent, class.bufnr)
    vim.lsp.buf_request(
      class.bufnr, 'textDocument/definition', params, self.search_handler
    )
  end
end


return Supertypes
