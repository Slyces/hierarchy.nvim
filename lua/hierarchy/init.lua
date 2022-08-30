local M = {}

local server = require('hierarchy.server')

M.handlers = require('hierarchy.handlers')
M.request = server.request
M.prepare = server.prepare
M.supertypes = server.supertypes
M.subtypes = server.subtypes

return M
