--[[ ──────────────────────── imports and aliases ───────────────────────── ]]--
---@module 'docs'

local prepare = RELOAD('hierarchy.server.prepare')
local utils = RELOAD('hierarchy.server.utils')

local validate = vim.validate

---@alias bufnode {node: tsnode, bufnr: integer}

---@alias search_cache {requests: table<int, boolean>, ctx: {params: {item: lsp_hierarchy_item}}, nodes: bufnode[], searcher: searcher}

---@type table<string, search_cache>
cache = {}


---@alias search_context {id: string, request_id: integer}

---Creates a custom structure for an LSP `textDocument` request params embedding
---the context of the current search to access global variables.
---
---@param search_id integer
---@param node tsnode
---@param bufnr integer
---@return {textDocument: {uri: string}, position: lsp_position, search: search_context}
local function build_params(search_id, node, bufnr)
    local params = vim.lsp.util.make_position_params()
    local row, col, _ = node:start()
    params.textDocument.uri = "file://" .. vim.api.nvim_buf_get_name(bufnr)
    params.position.line = row
    params.position.character = col

    local request_id = 1
    for max_requests, _ in ipairs(cache[search_id].requests) do
      request_id = request_id + 1
    end

    cache[search_id].requests[request_id] = true

    params.search = { id = search_id, request_id = request_id }
    return params
end


---Finalizes the search by converting all matches (stored as `tsnode`) to
---`lsp_hierarchy_item` then calling the handler.
---
---Deletes the cache entry for this search id.
---
---@param search_id any
---@param handler any
---@return searcher
local function finalize_search(search_id, handler)
  -- Convert each `bufnode` to an `lsp_hierarchy_item``
  local items = {}

  local item = cache[search_id].ctx.params.item
  local method_name = (item.kind == 12 and item.name) or nil
  local query = vim.treesitter.query.parse_query(
      utils.get_lang(), '(function_definition) @capture'
    )

  for i, bufnode in ipairs(cache[search_id].nodes) do
    local bufnr = bufnode.bufnr
    if i > 1 then  -- skip the first element (first class searched)

      -- We either add a method or a class to the items list
      if method_name and query then
        -- Method (if found)
        for _, method, _ in query:iter_captures(bufnode.node, bufnr) do
          local name = method:field("name")[1]
          if utils.get_node_text(name, bufnr) == method_name then
            local params = build_params(search_id, method, bufnr)
            table.insert(items, prepare(params)[1])
          end
        end
      else
        -- Class (should always be found)
        local params = build_params(search_id, bufnode.node, bufnr)
        table.insert(items, prepare(params)[1])
      end
    end
  end

  -- Call the handler
  handler(nil, items, cache[search_id].ctx, nil)

  -- Delete the cache entry for this search
  cache[search_id] = nil
end

---Generic callback handling the results from an LSP `textDocument` request.
---This implementation lays down the structure of a generic callback, performing
---the main steps of the algorithm. All steps that can have different
---implementations depending on which search we're performing are left to
---a generic class.
---
---@param searcher searcher search class containing the search logic
---@param err any
---@param result lsp_location[]
---@param ctx {params: {id: string, request_id: integer}}
---@param config any
local function search_handler(err, result, ctx, config)
  if not result then
    return
  end

  local search = ctx.params.search
  local searcher = cache[search.id].searcher

  -- Start subrequests for any of the results we got here
  for _, match in ipairs(result) do
    local bufnr = vim.fn.bufadd(vim.uri_to_fname(match.uri))
    local tree = utils.get_tree(bufnr)

    local node = utils.node_from_match(match, tree)
    local class = searcher:class_from_node(node, bufnr)

    if class then
      table.insert(cache[search.id].nodes, {node=class.node, bufnr=class.bufnr})

      searcher:send_requests(search.id, class)
    end
  end

  -- Mark the current request as done
  cache[search.id].requests[search.request_id] = nil

  -- Count the number of requests still pending
  local n = 0
  for k, v in pairs(cache[search.id].requests) do
    n = n + 1
  end

  -- If we're the last request to execute, call the callback for this search
  -- and remove the search from the cache
  if n == 0 then
    finalize_search(search.id, searcher.handler)
  end
end



--[[ ────────────────────── inheritance tree search ─────────────────────── ]]--
-- The objective of this algorithm is to build a list of references for the
-- parents/children classes of a given class.
--
-- In order to achieve this, we use two fundamental mechanisms:
--  • LSP to find references in other files in the project
--  • treesitter to know which symbol to investigate next
--
-- Additionally, as the main concept we'll interact with is `class_definition`
-- treesitter nodes, we coded a class `ClassNode` (type hint: `classnode`) to
-- provide utils around a `class_definition` node.


---@class searcher
---@field handler lsp_hierarchy_handler handler for the results of the search
local Searcher = {}

---@param handler lsp_hierarchy_handler handler for the results of the search
---@return table
function Searcher:new(handler)
  obj = {}
  setmetatable(obj, self)
  self.__index = self
  self.handler = handler
  self.search_handler = search_handler
  self.build_params = build_params
  return obj
end


---Builds a list of parent/children classes nodes for a symbol, then run an
---on the 
---
---@param params {item: lsp_hierarchy_item}
function Searcher:start(params)
  -- Find the `classnode` for the given item
  local bufnr = vim.fn.bufadd(vim.uri_to_fname(params.item.uri))
  local tree = utils.get_tree(bufnr)

  local node = utils.node_from_match(params.item, tree)

  local class = ClassNode:from_children(node, bufnr)
  local row, col, _ = class.node:start()
  local search_id = class.bufnr .. row .. col

  cache[search_id] = {
    requests = {},
    -- See |lsp-handler|
    ctx = { bufnr=bufnr, params=params, method=self:method(), client_id=-1 },
    nodes = {},
    searcher = self,
  }

  local params = build_params(search_id, class.node, class.bufnr)
  local ctx = cache[search_id].ctx
  ctx.params.search = {id=search_id, request_id=1}

  ---@type lsp_location
  local e_row, e_col, _ = class.node:end_()
  local match = {
    uri = "file:///" .. vim.api.nvim_buf_get_name(class.bufnr),
    range = {
      start = {
        line = row,
        character = col
      },
      ["end"] = {
        line = e_row,
        character = e_col,
      }
    }
  }
  search_handler(nil, {match}, ctx, nil)
end


--[[ ──────────────────────── methods to subclass ───────────────────────── ]]--

---For a given node that matched this `searcher`'s LSP request, find a valid
---`classnode` if any.
---
---@param node tsnode
---@param bufnr integer
---@return classnode|nil
function Searcher:class_from_node(node, bufnr)
  error("You should implement this method in a subclass")
end


---Sends the next batch of requests for a given `classnode`.
---
---@param search_id string
---@param class classnode
function Searcher:send_requests(search_id, class)
  error("You should implement this method in a subclass")
end


---LSP method supported by this search class.
---
---@return string
function Searcher:method()
  error("You should implement this method in a subclass")
end

--[[ ────────────────────────────────────────────────────────────────────── ]]--

return Searcher
