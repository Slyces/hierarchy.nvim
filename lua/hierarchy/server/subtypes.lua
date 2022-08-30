Searcher = RELOAD('hierarchy.server.search')
ClassNode = RELOAD('hierarchy.server.class_node')

Subtypes = Searcher:new()

---For a given node that matched this `searcher`'s LSP request, find a valid
---`classnode` if any.
---
---@param node tsnode
---@param bufnr integer
---@return classnode|nil
function Subtypes:class_from_node(node, bufnr)
  local parent = node:parent()

  if node:type() == "class_definition" then
    return ClassNode:from_children(node, bufnr)
  end

  if parent and parent:type() == "argument_list" then
    if parent:parent():type() == "class_definition" then
      return ClassNode:from_children(node, bufnr)
    end
  end
end


---Sends the next batch of requests for a given `classnode`.
---
---@param search_id string
---@param class classnode
function Subtypes:send_requests(search_id, class)
  local node = class.node:field("name")[1]
  local params = self.build_params(search_id, node, class.bufnr)
  params.context = { includeDeclaration = false }
  vim.lsp.buf_request(
    class.bufnr, 'textDocument/references', params, self.search_handler
  )
end


function Subtypes:method()
  return 'typeHierarchy/subtypes'
end

return Subtypes
