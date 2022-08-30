Searcher = RELOAD('heritage.search')

DownSearch = Searcher:new()

DownSearch.name = "DownSearcher"

---For a given node that matched this `searcher`'s LSP request, find a valid
---`classnode` if any.
---
---@param node tsnode
---@param bufnr integer
---@return classnode|nil
function DownSearch:class_from_node(node, bufnr)
  -- For `upward` requests, we're using `textDocument/definition` requests. This
  -- means we're landing on the name of the class. It's safe to just find the
  -- nearest `class_definition` tsnode.
  local parent = node:parent()
  local a, b, c = node:start()
  if node:type() == "class_definition" then
    return ClassNode:from_children(node, bufnr)
  end
  if parent and parent:type() == "argument_list" then
    P({parent:type(), parent:parent():type()})
    if parent:parent():type() == "class_definition" then
      return ClassNode:from_children(node, bufnr)
    end
  end
end


---Sends the next batch of requests for a given `classnode`.
---
---@param search_id string
---@param class classnode
function DownSearch:send_requests(search_id, class)
  local node = class.node:field("name")[1]
  local params = build_request(search_id, node, class.bufnr)
  params.context = { includeDeclaration = false }
  vim.lsp.buf_request(
    class.bufnr, 'textDocument/references', params, self.handler
  )
end

return DownSearch
