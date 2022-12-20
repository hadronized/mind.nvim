local mind_commands = require'mind.commands'
local mind_highlight = require'mind.highlight'
local mind_keymap = require'mind.keymap'
local mind_node = require'mind.node'
local mind_state = require'mind.state'
local mind_ui = require'mind.ui'
local notify = require'mind.notify'.notify
local path = require'plenary.path'

local M = {}

local function create_user_commands()
  vim.api.nvim_create_user_command(
    'MindOpenMain',
    function()
      require'mind'.open_main()
    end,
    { desc = 'Open the main Mind tree', }
  )

  vim.api.nvim_create_user_command(
    'MindToggleMain',
    function()
      require'mind'.toggle_main()
    end,
    {
      desc = 'Toggle main or project Mind tree',
    }
  )

  vim.api.nvim_create_user_command(
    'MindOpenProject',
    function(opts)
      require'mind'.open_project(opts.fargs[1] == 'global')
    end,
    {
      nargs = '?',
      desc = 'Open the project Mind tree',
    }
  )

  vim.api.nvim_create_user_command(
    'MindToggleProject',
    function(opts)
      require'mind'.toggle_project(opts.fargs[1] == 'global')
    end,
    {
      nargs = '?',
      desc = 'Toggle the project Mind tree',
    }
  )

  vim.api.nvim_create_user_command(
    'MindOpenSmartProject',
    function()
      require'mind'.open_smart_project()
    end,
    {
      desc = 'Open the project Mind tree',
    }
  )

  vim.api.nvim_create_user_command(
    'MindToggleSmartProject',
    function()
      require'mind'.toggle_smart_project()
    end,
    {
      desc = 'Toggle the project Mind tree',
    }
  )

  vim.api.nvim_create_user_command(
    'MindReloadState',
    function()
      require'mind'.reload_state()
    end,
    {
      desc = 'Reload Mind internal state',
    }
  )

  vim.api.nvim_create_user_command(
    'MindClose',
    function(opts)
      require'mind'.close()
    end,
    {
      desc = 'Close main or project Mind tree if open',
    }
  )
end

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', require'mind.defaults', opts or {})

  -- ensure the paths are expanded
  mind_state.expand_opts_paths(M.opts)

  -- keymaps
  mind_keymap.init_keymaps(M.opts)
  mind_commands.precompute_commands()

  -- user-commands
  create_user_commands()

  -- highlights
  mind_highlight.create_highlight_groups(M.opts)
end

-- Close the main or project tree if open.
M.close = function()
  mind_commands.close()
end

-- Open the main tree.
M.open_main = function()
  M.wrap_main_tree_fn(
    function(args)
      mind_commands.open_tree(
        args.get_tree,
        args.opts.persistence.data_dir,
        function() mind_state.save_main_state(args.opts) end,
        args.opts
      )
    end,
    M.opts
  )
end

-- Toggle the main tree view.
M.toggle_main = function()
  M.wrap_main_tree_fn(
    function(args)
      mind_commands.toggle(
        args.get_tree,
        args.opts.persistence.data_dir,
        function() mind_state.save_main_state(args.opts) end,
        args.opts
      )
    end,
    M.opts
  )
end

-- Open a project tree.
--
-- If `use_global` is set to `true`, will use the global persistence location.
M.open_project = function(use_global)
  M.wrap_project_tree_fn(
    function(args)
      mind_commands.open_tree(
        args.get_tree,
        args.data_dir,
        use_global
          and function() mind_state.save_main_state(args.opts) end
          or function() mind_state.save_local_state() end,
        args.opts
      )
    end,
    use_global,
    M.opts
  )
end

-- Toggle a project tree view.
M.toggle_project = function(use_global)
  M.wrap_project_tree_fn(
    function(args)
      mind_commands.toggle(
        args.get_tree,
        args.data_dir,
        use_global
          and function() mind_state.save_main_state(args.opts) end
          or function() mind_state.save_local_state() end,
        args.opts
      )
    end,
    use_global,
    M.opts
  )
end

-- Open a smart project tree.
M.open_smart_project = function()
  M.wrap_smart_project_tree_fn(
    function(args, use_global)
      mind_commands.open_tree(
        args.get_tree,
        args.data_dir,
        use_global
          and function() mind_state.save_main_state(args.opts) end
          or function() mind_state.save_local_state() end,
        args.opts
      )
    end,
    M.opts
  )
end

-- Toggle a smart project tree view.
M.toggle_smart_project = function()
  M.wrap_smart_project_tree_fn(
    function(args, use_global)
      mind_commands.toggle(
        args.get_tree,
        args.data_dir,
        use_global
          and function() mind_state.save_main_state(args.opts) end
          or function() mind_state.save_local_state() end,
        args.opts
      )
    end,
    M.opts
  )
end

-- Load state.
M.reload_state = function()
  mind_state.load_state(M.opts)
end

-- Wrap a function call expecting the main tree.
M.wrap_main_tree_fn = function(f, opts)
  opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  -- load the main tree
  mind_state.load_main_state(opts)

  local args = {
    get_tree = mind_state.get_main_tree,
    data_dir = opts.persistence.data_dir,
    save_tree = function() mind_state.save_main_state(opts) end,
    opts = opts,
  }

  f(args)
end

-- Wrap a function call expecting a project tree.
--
-- If the project tree doesn’t exist, it is automatically created.
M.wrap_project_tree_fn = function(f, use_global, opts)
  opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  local cwd = vim.fn.getcwd()
  if use_global then
    mind_state.load_main_state(opts)

    if mind_state.state.projects[cwd]== nil then
      mind_state.new_global_project_tree(cwd, opts)
    end
  else
    -- load the local state
    mind_state.load_local_state()

    if mind_state.local_tree == nil then
      mind_state.new_local_tree(cwd, opts)
    end
  end

  local save_tree =
    use_global and function() mind_state.save_main_state(opts) end
    or function() mind_state.save_local_state() end

  local args = {
    get_tree = function() return mind_state.get_project_tree(use_global and cwd or nil) end,
    data_dir = mind_state.get_project_data_dir(use_global, opts),
    save_tree = save_tree,
    opts = opts
  }

  f(args)
end

-- Smart project tree wrap.
--
-- If a local tree exists, wrap the local tree. Otherwise, wrap a global tree.
M.wrap_smart_project_tree_fn = function(f, opts)
  opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  local cwd = vim.fn.getcwd()
  local p = path:new(cwd, '.mind')

  if p:exists() and p:is_dir() then
    -- load the local state
    mind_state.load_local_state()

    local args = {
      get_tree = function() return mind_state.get_project_tree() end,
      data_dir = mind_state.get_project_data_dir(false, opts),
      save_tree = function() mind_state.save_local_state() end,
      opts = opts,
    }

    f(args, false)
  else
    -- otherwise, try to open a global project
    mind_state.load_main_state(opts)

    local tree = mind_state.state.projects[cwd]

    if tree ~= nil then
      -- a global project tree exists, use that
      local args = {
        get_tree = function() return mind_state.get_project_tree(cwd) end,
        data_dir = mind_state.get_project_data_dir(true, opts),
        save_tree = function() mind_state.save_main_state(opts) end,
        opts = opts,
      }

      f(args, true)
    else
      -- prompt the user whether they want a global or local tree
      mind_ui.with_input('What kind of project tree? (local/global) ', 'local', function(input)
        local get_tree
        local save_tree
        local use_global

        if input == 'local' then
          mind_state.new_local_tree(cwd, opts)
          get_tree = function() return mind_state.get_project_tree() end
          save_tree = function() mind_state.save_local_state() end
          use_global = false
        elseif input == 'global' then
          mind_state.new_global_project_tree(cwd, opts)
          get_tree = function() return mind_state.get_project_tree(cwd) end
          save_tree = function() mind_state.save_main_state(opts) end
          use_global = true
        end

        if get_tree == nil then
          notify('unrecognized project tree type, aborting', vim.log.levels.WARN)
          return
        end

        local args = {
          get_tree = get_tree,
          data_dir = mind_state.get_project_data_dir(use_global, opts),
          save_tree = save_tree,
          opts = opts,
        }

        f(args, true)
        save_tree()
      end)
    end
  end
end

return M
