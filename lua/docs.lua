---Module providing docs annotation missing from lua's runtime codebase

--[[ ────────────────────────── tree sitter node ────────────────────────── ]]--

---@class tsnode
---
---treesitter node, as described in |lua-treesitter-node|
local tsnode = {}

---@return tsnode
function tsnode:parent() end


---@param name string
---@return tsnode[] nodes
function tsnode:field(name) end


---@return integer row
---@return integer column
---@return integer bytes_count
---Get the node's start position. Return three values: the row, column
---and total byte count (all zero-based).
function tsnode:start() end


---@return integer row
---@return integer column
---@return integer bytes_count
---Get the node's end position. Return three values: the row, column
---and total byte count (all zero-based).
function tsnode:end_() end


---@return string
function tsnode:type() end


---Get an unique identifier for the node inside its own tree.
---  
---No guarantees are made about this identifier's internal
---representation, except for being a primitive lua type with value
---equality (so not a table). Presently it is a (non-printable) string.
---  
---Note: the id is not guaranteed to be unique for nodes from different
---trees.
---@return string
function tsnode:id() end


--[[ ──────────────────────────── LSP matches ───────────────────────────── ]]--

---@alias lsp_position {line: integer, row: integer} LSP server position, 0-based
---line and 0 based rows


---@alias lsp_range {start: lsp_position, end: lsp_position}


---@alias lsp_location {range: lsp_range, uri: string}
