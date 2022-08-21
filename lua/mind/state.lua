local M = {}

local path = require'plenary.path'
local notify = require'mind.notify'.notify
local mind_node = require'mind.node'

-- Load the state.
--
-- If CWD has a .mind/, the projects part of the state is overriden with its contents. However, the main tree remains in
-- in global state path.
M.load_state = function(opts)
  -- Global state.
  M.state = {
    -- Main tree, used when no specific project is wanted.
    tree = {
      contents = {
        { text = 'Main' },
      },
      type = mind_node.TreeType.ROOT,
      icon = opts.ui.root_marker,
    },

    -- Per-project trees; this is a map from the CWD of projects to the actual tree for that project.
    projects = {},
  }

  -- Local tree, for local projects.
  M.local_tree = nil

  -- required so that we can locate the file correctly if the user used ~ or relative paths
  M.expand_opts_paths(opts)

  if (opts.persistence.state_path == nil) then
    notify('cannot load shit', vim.log.levels.ERROR)
    return
  end

  local file = io.open(opts.persistence.state_path, 'r')

  if (file ~= nil) then
    local encoded = file:read()
    file:close()

    if (encoded ~= nil) then
      M.state = vim.json.decode(encoded)
    end
  end

  -- if there is a local state, we get it and replace the M.state.projects[the_project] with it
  local cwd = vim.fn.getcwd()
  local local_mind = path:new(cwd, '.mind')
  if (local_mind:is_dir()) then
    -- we have a local mind; read the projects state from there
    file = io.open(path:new(cwd, '.mind', 'state.json'):expand(), 'r')

    if (file == nil) then
      notify('cannot open local Mind tree')
    else
      local encoded = file:read()
      file:close()

      if (encoded ~= nil) then
        M.local_tree = vim.json.decode(encoded)
      end
    end
  end
end

M.expand_opts_paths = function(opts)
  opts.persistence.state_path = vim.fn.expand(opts.persistence.state_path)
  opts.persistence.data_dir = vim.fn.expand(opts.persistence.data_dir)
end

-- Save the state.
--
-- This is done at various times by commands whenever a change has happened.
M.save_state = function(opts)
  if (opts.persistence.state_path == nil) then
    return
  end

  M.pre_save()

  local state_path = path:new(opts.persistence.state_path)

  -- ensure the path exists
  if not state_path:exists() then
    state_path:touch({ parents = true })
  end

  local file = io.open(opts.persistence.state_path, 'w')

  if (file == nil) then
    notify(
      string.format('cannot save state at %s', opts.persistence.state_path),
      vim.log.levels.ERROR
    )
  else
    local encoded = vim.json.encode(M.state)
    file:write(encoded)
    file:close()
  end

  -- if there is a local state, we write the local project
  if M.local_tree ~= nil then
    local cwd = vim.fn.getcwd()
    local local_mind = path:new(cwd, '.mind')

    -- ensure the path exists
    if not local_mind:exists() then
      local_mind:mkdir({ parents = true })
    end

    if (local_mind:is_dir()) then
      -- we have a local mind
      file = io.open(path:new(cwd, '.mind', 'state.json'):expand(), 'w')

      if (file == nil) then
        notify(string.format('cannot save local project at %s', cwd), 4)
      else
        local encoded = vim.json.encode(M.local_tree)
        file:write(encoded)
        file:close()
      end
    end
  end
end

-- Function run to cleanse a tree before saving (some data shouldn’t be saved).
M.pre_save = function()
  if (M.state.tree.selected ~= nil) then
    M.state.tree.selected.node.is_selected = nil
    M.state.tree.selected = nil
  end

  if (M.local_tree ~= nil and M.local_tree.selected ~= nil) then
    M.local_tree.selected.node.is_selected = nil
    M.local_tree.selected = nil
  end

  for _, project in ipairs(M.state.projects) do
    if (project.selected ~= nil) then
      project.selected.node.is_selected = nil
      project.selected = nil
    end
  end
end

-- Get the project data directory.
--
-- If a local tree exists, its path data is returned. Otherwise, we use the one in opts.persistence.data_dir.
M.get_project_data_dir = function(opts)
  if M.local_tree ~= nil then
    return '.mind/data'
  end

  return opts.persistence.data_dir
end

return M
