local M = {}

local server = RELOAD('hierarchy.server')

M.handlers = RELOAD('hierarchy.handlers')
M.request = server.request
M.supertypes = server.supertypes
M.subtypes = server.subtypes

--[> ─────────────────────────────── utils ──────────────────────────────── <]--

-----@param nodes bufnode[]
--function print_nodes(nodes)
  --for i, node in ipairs(nodes) do
    --P({i, node.bufnr, node.node, get_node_text(node.node, node.bufnr)})
  --end
--end

-----Utils function jumping to a `tsnode` in any given buffer
-----
-----@param node tsnode
-----@param bufnr integer
--function goto_node(node, bufnr)
  --local local_bufnr = vim.api.nvim_win_get_buf(0)
  --if bufnr ~= local_bufnr then
    --vim.api.nvim_set_current_buf(bufnr)
    --ts_utils.goto_node(node, nil, true)
  --else
    --ts_utils.goto_node(node, nil)
  --end
--end

--[> ────────────────────────── callback methods ────────────────────────── <]--

-----Loads all matches in the quickfix list
-----
-----@param title string
-----@param nodes bufnode[]
--function load_qf(title, nodes)
  --local items = {}
  --for _, node in ipairs(nodes) do
    --local line, col, _ = node.node:start()
    --table.insert(items, {
      --filename = vim.api.nvim_buf_get_name(node.bufnr),
      --text = vim.api.nvim_buf_get_lines(node.bufnr, line, line + 1, false)[1],
      --lnum = line + 1,
      --col = col + 1,
    --})
  --end

  --vim.fn.setqflist({}, ' ', {title = title, items = items})
  --vim.api.nvim_command("botright copen")
--end


-----Loads all method matches in the quickfix list
-----
-----@param method_name string
-----@param nodes bufnode[]
--function load_method_qf(method_name, nodes)
  --local method_nodes = {}
  --for _, node in ipairs(nodes) do
    --local class = ClassNode:from_children(node.node, node.bufnr)
    --local method_node = class:find_method(method_name)
    --if method_node then
      --table.insert(method_nodes, {node=method_node, bufnr=node.bufnr})
    --end
  --end

  --load_qf("Parent methods", method_nodes)
--end


-----Jumps to the first parent class, if any
-----
-----@param nodes bufnode[]
--function go_first_parent(nodes)
  --local parent = nodes[2]
  --if parent then
    --local bufnr = vim.api.nvim_win_get_buf(0)
    --goto_node(parent.node, parent.bufnr)
  --end
--end


-----Jumps to the first method defined by a parent class, if any
-----
-----@param method_name string
-----@param nodes bufnode[]
--function go_first_method(method_name, nodes)
  --local bufnr = vim.api.nvim_win_get_buf(0)

  --for i, parent in ipairs(nodes) do
    --local class = ClassNode:from_children(parent.node, parent.bufnr)
    --local method_node = class:find_method(method_name)
    --if method_node then
      --goto_node(method_node, parent.bufnr)
    --end
  --end
--end


--[> ─────────────────────────── public methods ─────────────────────────── <]--

--function M.jump_up()
  --local node = ts_utils.get_node_at_cursor()
  --local class = ClassNode:from_children(node, 0)

  --if node:parent():type() == "function_definition" then
    --callback = function(nodes)
      --return go_first_method(get_node_text(node, 0), nodes)
    --end
  --else
    --callback = go_first_parent
  --end

  --UpSearcher:new("up", callback):start(class)
--end


--function M.qf_up()
  --local node = ts_utils.get_node_at_cursor()
  --local class = ClassNode:from_children(node, 0)
  ----reload('hierarchy.search').search(class, go_first_parent)

  --if node:parent():type() == "function_definition" then
    --callback = function(nodes)
      --return load_method_qf(get_node_text(node, 0), nodes)
    --end
  --else
    --callback = function(nodes)
      --return load_qf("parent classes", nodes)
    --end
  --end

  --UpSearcher:new("up", callback):start(class)
--end


--function M.jump_down()
  --local node = ts_utils.get_node_at_cursor()
  --local class = ClassNode:from_children(node, 0)

  --if node:parent():type() == "function_definition" then
    --callback = function(nodes)
      --return go_first_method(get_node_text(node, 0), nodes)
    --end
  --else
    --callback = go_first_parent
  --end

  --DownSearcher:new("down", callback):start(class)
--end


--function M.qf_down()
  --local node = ts_utils.get_node_at_cursor()
  --local class = ClassNode:from_children(node, 0)
  ----reload('hierarchy.search').search(class, go_first_parent)

  --if node:parent():type() == "function_definition" then
    --callback = function(nodes)
      --return load_method_qf(get_node_text(node, 0), nodes)
    --end
  --else
    --callback = function(nodes)
      --return load_qf("parent classes", nodes)
    --end
  --end

  --DownSearcher:new("up", callback):start(class)
--end


return M
