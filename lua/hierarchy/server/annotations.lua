---Module providing docs annotation missing from lua's runtime codebase

--[[ ────────────────────────── tree sitter node ────────────────────────── ]]--

-- Please note that this interface is *incomplete*. Only the methods that were
-- useful at some point or another of the development of this plugin were added

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


--[[ ──────────────────────────────── LSP ───────────────────────────────── ]]--

---@alias lsp_handler fun(err: any, result: any, ctx: any, config: any): nil

---@alias lsp_hierarchy_handler fun(err: any, result: lsp_hierarchy_item[]|nil, ctx: {params: {item: lsp_hierarchy_item}}, config: any)

---@alias lsp_position {line: integer, character: integer} LSP server position, 0-indexed
---line and 0 based rows

---@alias lsp_range {start: lsp_position, end: lsp_position}

---@alias lsp_location {range: lsp_range, uri: string}

---@alias lsp_params {textDocument: {uri: string}, position: lsp_position}

---@alias lsp_symbol_kind
---| 1 # File
---| 2 # Module
---| 3 # Namespace
---| 4 # Package
---| 5 # Class
---| 6 # Method
---| 7 # Property
---| 8 # Field
---| 9 # Constructor
---| 10 # Enum
---| 11 # Interface
---| 12 # Function
---| 13 # Variable
---| 14 # Constant
---| 15 # String
---| 16 # Number
---| 17 # Boolean
---| 18 # Array
---| 19 # Object
---| 20 # Key
---| 21 # Null
---| 22 # EnumMember
---| 23 # Struct
---| 24 # Event
---| 25 # Operator
---| 26 # TypeParameter

---@alias lsp_symbol_tag
---| 1 # Deprecated

---@alias lsp_hierarchy_item {name: string, uri: string, kind: lsp_symbol_kind, tags?: lsp_symbol_tag[]|nil, detail?: string|any, uri: string, range: lsp_range, selectionRange: lsp_range, data?: any}
---Type Hierarchy Iterm as returned by the `textDocument/prepareTypeHierarchy`
---request in the LSP specification `3.17`
---
---@see https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_prepareTypeHierarchy
