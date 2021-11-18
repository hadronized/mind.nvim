-- mind.nvim, a small note taking tool with fuzzy search support.

local path = require'plenary.path'
local scandir = require'plenary.scandir'
local telescope_pickers = require "telescope.pickers"
local telescope_finders = require "telescope.finders"
local telescope_conf = require("telescope.config").values

local M = {}
local config = {}
local default_config = {
  dir = {
    notes = "~/mind/notes",
    journal = "~/mind/journal",
    todo = "~/mind/tasks/todo",
    wip = "~/mind/tasks/wip",
    done = "~/mind/tasks/done",
  }
}

-- Setup mind.nvim.
function M.setup(cfg)
  config = cfg or {}
  setmetatable(config, { __index = default_config })

  for _, p in pairs(config.dir) do
    local dir_path = path:new(path:new(p):expand())
    if not dir_path:exists() then
      dir_path:mkdir({ parents = true })
    end
  end
end

-- Turn a path into a nice representation.
local function pretty_entry(p)
  return string.match(p, '/[^/]*$'):sub(2, -4)
end

local function open_node(dir, prompt)
  local files = scandir.scan_dir(path:new(dir):expand())
  telescope_pickers.new({}, {
    prompt_title = prompt,
    finder = telescope_finders.new_table {
      results = files,
      entry_maker = function(entry)
        return {
          value = entry,
          display = pretty_entry(path:new(entry).filename),
          ordinal = entry,
        }
      end
    },
    sorter = telescope_conf.generic_sorter(),
  }):find()
end

-- Sanitize a node name.
--
-- This is important to remove things like /, for instance.
local function sanitize_node_name(name)
  local n = name:gsub('/', '_')
  return n
end

local function new_node(dir, prompt)
  local node_name = vim.fn.input(prompt)

  if node_name == "" then
    return
  end

  node_name = dir .. '/' .. sanitize_node_name(node_name)

  if not string.match(node_name, '.md$') then
    node_name = node_name .. '.md'
  end

  vim.cmd(string.format(':e %s', node_name))
end

local function move_node(dir_dest)
  local current_path = vim.api.nvim_buf_get_name(0)
  local file_name = current_path:match('/[^/]*$'):sub(2)
  local dest = path:new(string.format('%s/%s', dir_dest, file_name )):expand()

  print('renaming to', dest)
  path:new(current_path):rename({ new_name = dest })

  vim.api.nvim_buf_delete(0, { force = true })
end

function M.open_note()
  open_node(config.dir.notes, 'Open a note')
end

function M.new_note()
  new_node(config.dir.notes, 'New note: ')
end

function M.open_journal()
  open_node(config.dir.journal, 'Open a journal note')
end

function M.open_daily()
  local today = vim.fn.strftime('%Y%m%d')
  local p = string.format('%s/%s.md', config.dir.journal, today)

  vim.cmd(string.format(':e %s', p))
end

function M.open_todo()
  open_node(config.dir.todo, 'Open a TODO')
end

function M.new_todo()
  new_node(config.dir.todo, 'New TODO: ')
end

function M.open_wip()
  open_node(config.dir.wip, 'Open a WIP')
end

function M.new_wip()
  new_node(config.dir.wip, 'New WIP: ')
end

function M.open_done()
  open_node(config.dir.done, 'Open a DONE')
end

function M.new_done()
  new_node(config.dir.done, 'New DONE: ')
end

function M.mark_todo()
  move_node(config.dir.todo)
end

function M.mark_wip()
  move_node(config.dir.wip)
end

function M.mark_done()
  move_node(config.dir.done)
end

return M
