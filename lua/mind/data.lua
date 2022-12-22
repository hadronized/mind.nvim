-- Data files.

local M = {}

local notify = require'mind.notify'.notify
local path = require'plenary.path'

-- Create a new random file in a given directory.
--
-- Return the path to the created file, expanded if required.
M.new_data_file = function(dir, name, extension, content, should_expand)
  -- ensure the directory exists
  local dir_path = path:new(dir)
  if not dir_path:exists() then
    dir_path:mkdir({ parents = true })
  end

  -- filter the name
  name = name:gsub('[^%w-]', ' ') -- remove anything that is not a word or a dash
  name = name:gsub('%s+', '-') -- replace consecutive spaces with a single one
  name = name:gsub('-+', '-') -- replace consecutive dashes with a single one
  name = name:gsub('^-', '') -- remove leading dash
  name = name:gsub('-$', '') -- remove trailing dash

  local filename = vim.fn.strftime('%Y%m%d%H%M%S-') .. name .. extension
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

-- Deletes the given file.
M.delete_data_file = function(file_path)
  os.remove(file_path)
end


return M
