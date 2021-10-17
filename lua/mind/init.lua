-- mind.nvim, a small note taking tool with fuzzy search support.

local path = require'plenary.path'
local telescope_blt = require'telescope.builtin'

local M = {}
local config = {}
local default_config = {
  node_dir = "~/mind"
}

-- Setup mind.nvim.
function M.setup(cfg)
  config = cfg or {}
  setmetatable(config, { __index = default_config })

  local node_dir_path = path:new(path:new(config.node_dir):expand())
  if not node_dir_path:exists() then
    node_dir_path:mkdir()
  end
end

-- Search for a node.
function M.open_node()
  telescope_blt.fd { cwd = config.node_dir }
end

-- Create a new node.
function M.create_node()
  local node_name = vim.fn.input('New mind node: ')

  if node_name == "" then
    return
  end

  node_name = config.node_dir .. '/' .. node_name

  if not string.match(node_name, '.md$') then
    node_name = node_name .. '.md'
  end

  vim.cmd(string.format(':e %s', node_name))
end

return M
