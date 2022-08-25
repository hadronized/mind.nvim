local mind_commands = require'mind.commands'
local mind_highlight = require'mind.highlight'
local mind_keymap = require'mind.keymap'
local mind_node = require'mind.node'
local mind_state = require'mind.state'
local notify = require'mind.notify'.notify

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
    'MindReloadState',
    function(opts)
      require'mind'.reload_state()
    end,
    {
      desc = 'Reload Mind internal state',
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
          and function() mind_state.save_main_state(opts) end
          or function() mind_state.save_local_state() end,
        args.opts
      )
    end,
    use_global,
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
  if (use_global) then
    local tree = mind_state.state.projects[cwd]

    if (tree == nil) then
      tree = {
        uid = vim.fn.strftime('%Y%m%d%H%M%S'),
        contents = {
          { text = cwd:match('^.*/(.+)$') },
        },
        type = mind_node.TreeType.ROOT,
        icon = opts.ui.root_marker,
      }
      mind_state.state.projects[cwd] = tree
    end
  else
    -- load the local state
    mind_state.load_local_state()

    if mind_state.local_tree == nil then
      notify('creating a new local tree')
      mind_state.local_tree = {
        uid = vim.fn.strftime('%Y%m%d%H%M%S'),
        contents = {
          { text = cwd:match('^.*/(.+)$') },
        },
        type = mind_node.TreeType.LOCAL_ROOT,
        icon = opts.ui.root_marker,
      }
    end
  end

  local save_tree =
    use_global and function() mind_state.save_main_state(opts) end
    or function() mind_state.save_local_state() end

  local args = {
    get_tree = function() return mind_state.get_project_tree(use_global and cwd or nil) end,
    data_dir = mind_state.get_project_data_dir(opts),
    save_tree = save_tree,
    opts = opts
  }

  f(args)
end

return M
