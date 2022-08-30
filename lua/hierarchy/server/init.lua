local M = {}

---@module 'hierarchy.server.annotation'

prepare = require('hierarchy.server.prepare')
Supertypes = require('hierarchy.server.supertypes')
Subtypes = require('hierarchy.server.subtypes')

---Low level interface of `hierarchy.nvim`. Sends an LSP request with the same
---interface as `vim.lsp.buf_request`.
---  
---Supports only the methods:
--- - `textDocument/prepareTypeHierarchy`
--- - `typeHierarchy/supertypes`
--- - `typeHierarchy/subtypes`
---  
---If the method requested is supported by one of your current LSP clients,
---delegates the call to `vim.lsp.buf_request`. If it's not supported, use the
---plugin's implementation for this request.
---Returns a client id of -1 if the plugin is providing the request.
---  
---@see |vim.lsp.buf_request|
---
---@param bufnr number Buffer handle, or 0 for current.
---@param method string LSP method name
---@param params table|nil Parameters to send to the server
---@param handler lsp_handler|nil See |lsp-handler|
function M.request(bufnr, method, params, handler)
  vim.validate({
    bufnr={bufnr, 'n'},
    method={method, 's'},
    params={params, 't'},
    handler={handler, 'f'}
  })

  -- Check for support in any existing client.
  -- Note: the current 'lsp.client.supports_method' implementation assumes that
  -- if a method is unknown by the native LSP client, it's supported.
  local supported_clients = {}
  local method_supported = false
  vim.lsp.for_each_buffer_client(bufnr, function(client, client_id)
    -- 'unknown' ⇒ true workaround
    local method_known = vim.lsp._request_name_to_capability[method]
    if method_known and client.supports_method('textDocument/prepareTypeHierarchy') then
      method_supported = true
      table.insert(supported_clients, client_id)
    end
  end)

  if method_supported then
    return vim.lsp.buf_request(bufnr, method, params, handler)
  end

  if method == 'textDocument/prepareTypeHierarchy' then
    local items = prepare(params)
    handler(nil, items, {params=params}, nil)
  elseif method == 'typeHierarchy/supertypes' then
    Supertypes:new(handler):start(params)
  elseif method == 'typeHierarchy/subtypes' then
    Subtypes:new(handler):start(params)
  else
    error("Unsupported method for hierarchy.request: '" .. method .. "'")
  end

  return -1, -1
end


local function type_hierarchy(method, handler)
  local params = vim.lsp.util.make_position_params()
  local prepare_method = 'textDocument/prepareTypeHierarchy'
  M.request(0, prepare_method, params, function(err, result, ctx, config)
    if not result then
      return
    end
    M.request(0, method, {item=result[1]}, handler)
  end)
end


---Higher level interface for 'hierarchy.nvim'. Send an LSP request for
---`prepareTypeHierarchy` then `typeHierarchy/supertypes` for the symbol under
---the cursor, using the provided handler.
---
---@param handler lsp_hierarchy_handler
function M.supertypes(handler)
  type_hierarchy('typeHierarchy/supertypes', handler)
end


---Higher level interface for 'hierarchy.nvim'. Send an LSP request for
---`prepareTypeHierarchy` then `typeHierarchy/subtypes` for the symbol under
---the cursor, using the provided handler.
---
---@param handler lsp_hierarchy_handler
function M.subtypes(handler)
  type_hierarchy('typeHierarchy/subtypes', handler)
end

M.prepare = prepare

return M
