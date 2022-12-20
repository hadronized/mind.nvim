local M = {}

---A simple shortcut function used to notify users.
---@param msg string
---@param lvl integer one of `vim.log.levels.{OFF,WARN,INFO,TRACE,ERROR,DEBUG}`
M.notify = function(msg, lvl)
  vim.notify(msg, lvl, { title = 'Mind', icon = '' })
end

return M
