local M = {}

local path = require'plenary.path'
local notify = require'mind.notify'.notify
local mind_node = require'mind.node'

-- Expand opts paths.
--
-- They might contain relative symbols that need to be expanded (.., ~, etc.).
M.expand_opts_paths = function(opts)
  opts.persistence.state_path = vim.fn.expand(opts.persistence.state_path)
  opts.persistence.data_dir = vim.fn.expand(opts.persistence.data_dir)
end

-- Get the main tree.
M.get_main_tree = function()
  return M.state.tree
end

-- Get a project tree.
M.get_project_tree = function(cwd)
  if cwd ~= nil then
    return M.state.projects[cwd]
  else
    return M.local_tree
  end
end

M.new_global_project_tree = function(cwd, opts)
  notify('creating a new global project tree')

  local tree = {
    uid = vim.fn.strftime('%Y%m%d%H%M%S'),
    contents = {
      { text = cwd:match('^.*/(.+)$') },
    },
    type = mind_node.TreeType.ROOT,
    icon = opts.ui.root_marker,
  }

  M.state.projects[cwd] = tree

  return tree
end

M.new_local_tree = function(cwd, opts)
  notify('creating a new local tree')

  M.local_tree = {
    uid = vim.fn.strftime('%Y%m%d%H%M%S'),
    contents = {
      { text = cwd:match('^.*/(.+)$') },
    },
    type = mind_node.TreeType.LOCAL_ROOT,
    icon = opts.ui.root_marker,
  }

  return M.local_tree
end

-- Load the main state.
M.load_main_state = function(opts)
  -- Global state.
  M.state = {
    -- Main tree, used when no specific project is wanted.
    tree = {
      uid = vim.fn.strftime('%Y%m%d%H%M%S'),
      contents = {
        { text = 'Main' },
      },
      type = mind_node.TreeType.ROOT,
      icon = opts.ui.root_marker,
    },

    -- Per-project trees; this is a map from the CWD of projects to the actual tree for that project.
    projects = {},
  }

  if (opts.persistence.state_path == nil) then
    notify('cannot load shit', vim.log.levels.ERROR)
    return
  end

  local file = io.open(opts.persistence.state_path, 'r')

  if (file ~= nil) then
    local encoded = file:read('*a')
    file:close()

    if (encoded ~= nil) then
      M.state = vim.json.decode(encoded)
    end
  end

  -- ensure we have a UID
  M.state.tree.uid = M.state.tree.uid or vim.fn.strftime('%Y%m%d%H%M%S')

  for _, tree in ipairs(M.state.projects) do
    tree.uid = tree.uid or vim.fn.strftime('%Y%m%d%H%M%S')
  end
end

-- Save the main state.
M.save_main_state = function(opts)
  if (opts.persistence.state_path == nil) then
    return
  end

  local state_path = path:new(opts.persistence.state_path)

  -- ensure the path exists
  if not state_path:exists() then
    state_path:touch({ parents = true })
  end

  local file = io.open(opts.persistence.state_path, 'w')

  if (file == nil) then
    notify(
      string.format('cannot save main state at %s', opts.persistence.state_path),
      vim.log.levels.ERROR
    )
  else
    local encoded = vim.json.encode(M.state)
    file:write(encoded)
    file:close()
  end
end

-- Load the local state.
M.load_local_state = function()
  -- Local tree, for local projects.
  M.local_tree = nil

  local cwd = vim.fn.getcwd()
  local local_mind = path:new(cwd, '.mind')
  if (local_mind:is_dir()) then
    -- we have a local mind; read the projects state from there
    local file = io.open(path:new(cwd, '.mind', 'state.json'):expand(), 'r')

    if (file == nil) then
      notify('cannot open local Mind tree')
    else
      local encoded = file:read('*a')
      file:close()

      if (encoded ~= nil) then
        M.local_tree = vim.json.decode(encoded)

        -- ensure we have a UID
        M.local_tree.uid = M.local_tree.uid or vim.fn.strftime('%Y%m%d%H%M%S')

        M.local_cwd = cwd
      end
    end
  end
end

-- Save the local state.
M.save_local_state = function()
  if M.local_tree ~= nil then
    local cwd = vim.fn.getcwd()

    if M.local_cwd and cwd ~= M.local_cwd then
      notify('refusing to save local state: differs from when it was loaded', vim.log.levels.ERROR)
      notify(string.format('hint: loaded as %s, try saving as %s', M.local_cwd, cwd), vim.log.levels.INFO)
      notify(string.format('hint: cd to %s in order to save the tree', M.local_cwd), vim.log.levels.INFO)
      return
    end

    local local_mind = path:new(cwd, '.mind')

    -- ensure the path exists
    if not local_mind:exists() then
      local_mind:mkdir({ parents = true })
    end

    if (local_mind:is_dir()) then
      -- we have a local mind
      local file = io.open(path:new(cwd, '.mind', 'state.json'):expand(), 'w')

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

-- Load the full state (i.e. main and projects).
M.load_state = function(opts)
  M.load_main_state(opts)
  M.load_local_state()
end

-- Save the full state.
M.save_state = function(opts)
  M.save_main_state(opts)
  M.save_local_state()
end

-- Get the project data directory.
M.get_project_data_dir = function(use_global, opts)
  if use_global then
    return opts.persistence.data_dir
  end

  return '.mind/data'
end

return M
