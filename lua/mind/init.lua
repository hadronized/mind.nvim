local path = require'plenary.path'
local mind_commands = require'mind.commands'
local mind_data = require'mind.data'
local mind_keymap = require'mind.keymap'
local mind_node = require'mind.node'
local mind_state = require'mind.state'

local M = {}

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', require'mind.defaults', opts or {})

  -- load tree state
  mind_state.load_state(M.opts)

  -- keymaps
  mind_keymap.init_keymaps(M.opts)
  mind_commands.precompute_commands()
end

-- Open the main tree.
M.open_main = function()
  M.wrap_main_tree_fn(
    function(tree)
      mind_commands.open_tree(tree, M.opts.persistence.data_dir, M.opts)
    end
  )
end

-- Open a project tree.
--
-- If `use_global` is set to `true`, will use the global persistence location.
M.open_project = function(use_global)
  M.wrap_project_tree_fn(
    function(tree)
      mind_commands.open_tree(tree, mind_state.get_project_data_dir(), M.opts)
    end,
    false,
    nil,
    use_global
  )
end

-- Wrap a function call expecting a tree by extracting from the state the right tree, depending on CWD.
--
-- The `save` argument will automatically save the state after the function is done, if set to `true`.
M.wrap_tree_fn = function(f, save, opts)
  local cwd = vim.fn.getcwd()
  local project_tree = mind_state.projects[cwd]

  if (project_tree == nil) then
    M.wrap_main_tree_fn(f, save,  opts)
  else
    M.wrap_project_tree_fn(f, save, project_tree, false, opts)
  end
end

-- Wrap a function call expecting a tree with the main tree.
M.wrap_main_tree_fn = function(f, save, opts)
  f(mind_state.state.tree)

  if (save) then
    mind_state.save_state(opts)
  end
end

-- Wrap a function call expecting a project tree.
--
-- If the project tree doesn’t exist, it is automatically created.
M.wrap_project_tree_fn = function(f, save, tree, use_global, opts)
  if (tree == nil) then
    if (mind_state.local_tree == nil or use_global) then
      local cwd = vim.fn.getcwd()
      tree = mind_state.projects[cwd]

      if (tree == nil) then
        tree = {
          contents = {
            { text = cwd:match('^.+/(.+)$') },
          },
          type = mind_node.TreeType.ROOT,
          icon = M.opts.ui.root_marker,
        }
        mind_state.projects[cwd] = tree
      end
    else
      tree = mind_state.local_tree
    end
  end

  f(tree)

  if (save) then
    mind_state.save_state(opts)
  end
end

return M
