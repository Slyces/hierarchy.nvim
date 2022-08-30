--[[ ──────────────────────── imports and aliases ───────────────────────── ]]--
---@module 'docs'

local ts_utils = require('nvim-treesitter.ts_utils')
local ClassNode = RELOAD('heritage.class_node')

local validate = vim.validate
local get_node_text = vim.treesitter.query.get_node_text

local lang = function()
  return vim.bo.filetype
end

---@alias bufnode {node: tsnode, bufnr: integer}

---@alias search_table {requests: table<int, boolean>, nodes: bufnode[], searcher: searcher}

---@alias callback fun(nodes: bufnode[]): nil

---@alias direction
---| '"up"' # searches the inheritance tree *upward*
---| '"down"' # searches the inheritance tree *downwards*
---| '"both"' # searches the inheritance tree *upwards and downwards*

---@type table<string, search_table>
cache = {}


--[[ ─────────────────────────────── utils ──────────────────────────────── ]]--

---Loads a treesitter tree for a given bufnr
---
---@param bufnr integer: number of the buffer to parse
---@return tsnode # the treesitter tree for this file
function get_tree(bufnr)
  vim.fn.bufload(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, lang())
  return parser:parse()[1]
end


---Finds the node for a given LSP match in a buffer
---
---@param match lsp_location: match returned by an LSP request
---@param tree any
---@return tsnode
function node_from_match(match, tree)
  return tree:root():descendant_for_range(
    match.range.start.line,
    match.range.start.character,
    match.range["end"].line,
    match.range["end"].character
  )
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
local function handler(err, result, ctx, config)
  if not result then
    return
  end

  local search = ctx.params.search
  local searcher = cache[search.id].searcher

  -- Start subrequests for any of the results we got here
  for _, match in ipairs(result) do
    local bufnr = vim.fn.bufadd(vim.uri_to_fname(match.uri))
    local tree = get_tree(bufnr)

    local node = node_from_match(match, tree)
    local class = searcher:class_from_node(node, bufnr)

    if class then
      local class_name = class.node:field("name")[1]
      table.insert(cache[search.id].nodes, {node=class_name, bufnr=class.bufnr})

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
    searcher.callback(cache[search.id].nodes)
    cache[search.id] = nil
  end

end


---Creates the minimum structure for an LSP textDocument request.
---
---@param search_id integer
---@param node tsnode
---@param bufnr integer
function build_request(search_id, node, bufnr)
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
---@field direction direction the direction of this search class
---@field callback callback callback on search end
local Searcher = {}

---@param direction direction
---@param callback callback
---@return table
function Searcher:new(direction, callback)
  obj = {}
  setmetatable(obj, self)
  self.__index = self
  self.direction = direction
  self.callback = callback
  self.handler = handler
  return obj
end


---Builds a list of parent/children classes nodes for a symbol, then run
---a function on the final list
---
---@param class classnode
---@param finalizer fun(nodes: bufnode[])
function Searcher:start(class)
  local row, col, _ = class.node:start()
  local search_id = class.bufnr .. row .. col

  cache[search_id] = {
    requests = {},
    nodes = {},
    searcher = self,
  }

  local params = build_request(search_id, class.node, class.bufnr)
  local ctx = {params=params, search={id=search_id, request_id=1}}

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
  handler(nil, {match}, ctx, nil)
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

--[[ ────────────────────────────────────────────────────────────────────── ]]--

return Searcher
