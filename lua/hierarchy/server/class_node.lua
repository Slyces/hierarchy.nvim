--[[ ───────────────────────── imports / aliases ────────────────────────── ]]--
local utils = RELOAD('hierarchy.server.utils')


--[[ ───────────────────────────── Class Node ───────────────────────────── ]]--

---@class classnode
---@field node tsnode: `class-definition` node for this class
---@field bufnr integer: number of the buffer where this node is found
---@field bufnr integer: number of the buffer where this node is found
---
---Wrapper around tsnode |lua-treesitter-node| providing methods specific for
---a `class_definition` node. This class is limited to treesitter capabilities
---(i.e. current buffer).
local ClassNode = { node = nil, bufnr = nil }

---Create a new ClassNode instance. It's a wrapper around `tsnode` providing
---methods specific to a `class_definition` node.
---
---@param node tsnode|any
---@param bufnr integer
---@return classnode: `ClassNode` instance
function ClassNode:new(node, bufnr)
  if node == nil or bufnr == nil then
    return nil
  end
  obj = {}
  setmetatable(obj, self)
  self.__index = self
  self.node = node
  self.bufnr = bufnr
  return obj
end


---Create a new ClassNode instance from one of its children. Returns the first
---valid class found amongst the parents of the children.
---
---@param children tsnode: children `tsnode` of a 'class_definition'
---@param bufnr? integer: buffer for this children
---@return classnode|nil: first parent class found for this children node
function ClassNode:from_children(children, bufnr)
  bufnr = bufnr or 0

  local parent_class = utils.first_parent_of_type(children, 'class_definition')
  if parent_class then
    return ClassNode:new(parent_class, bufnr)
  end
end


---Name of the current class
---
---@return string name: the text of the current class name
function ClassNode:name()
  local name_node = self.node:field("name")[1]
  return utils.get_node_text(name_node, self.bufnr)
end


---Finds a method within this class by name
---
---@param name string: name of the method to find
---@return tsnode|nil method_node: tsnode for the method identifier, if found
function ClassNode:find_method(name)
  for children in self.node:field("body")[1]:iter_children() do
    ---@type tsnode?
    local identifier = nil

    -- The definition can be found in different places depending on decorators
    if children:type() == "decorated_definition" then
      identifier = children:field("definition")[1]:field("name")[1]
    elseif children:type() == "function_definition" then
      identifier = children:field("name")[1]
    end

    if identifier and utils.get_node_text(identifier, self.bufnr) == name then
      return identifier
    end
  end
  return nil
end


---Finds all the superclasses identifiers for this class
---
---@return table: table of identifier TSNode for the parents of this class
function ClassNode:direct_parents()
  local superclasses = self.node:field("superclasses")

  local parents = {}
  for _, superclass in ipairs(superclasses) do
    for node in superclass:iter_children() do
      if node:type() == "identifier" then
        table.insert(parents, node)
      elseif node:type() == "subscript" then
        table.insert(parents, node:field("value")[1])
      end
    end
  end
  return parents
end


function ClassNode:hash()
  return self.bufnr .. self.node:id()
end


return ClassNode
