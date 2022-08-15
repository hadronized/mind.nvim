-- Data files.

local M = {}

local notify = require'mind.notify'.notify
local path = require'plenary.path'

-- Create a new random file in a given directory.
--
-- Return the path to the created file, expanded if required.
M.new_data_file = function(dir, name, content, should_expand)
  local filename = vim.fn.strftime('%Y%m%d%H%M%S-') .. name
  local p = path:new(dir, filename)
  local file_path = (should_expand and p:expand()) or tostring(p)

  local file = io.open(file_path, 'w')

  if (file == nil) then
    notify('cannot open data file: ' .. file_path)
    return nil
  end

  file:write(content)
  file:close()

  return file_path
end

return M
