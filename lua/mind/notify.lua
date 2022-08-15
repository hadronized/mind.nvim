-- A simple shortcut function used to notify users.

local M = {}

M.notify = function(msg, lvl)
  vim.notify(msg, lvl, { title = 'Mind', icon = '' })
end

return M
