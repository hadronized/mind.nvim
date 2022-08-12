local path = require'plenary.path'
local mind_node = require'mind.node'
local mind_state = require'mind.state'
local mind_data = require'mind.data'

local M = {}

local function notify(msg, lvl)
  vim.notify(msg, lvl, { title = 'Mind', icon = '' })
end

M.TreeType = {
  ROOT = 0,
  LOCAL_ROOT = 1,
}

M.MoveDir = {
  ABOVE = 0,
  BELOW = 1,
  INSIDE_START = 2,
  INSIDE_END = 3,
}

local commands = {
  toggle_node = function(tree)
    M.toggle_node_cursor(tree)
    mind_state.save_state(M.opts)
  end,

  quit = function(tree)
    M.reset(tree)
    M.close(tree)
  end,

  add_above = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.ABOVE)
    mind_state.save_state(M.opts)
  end,

  add_below = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.BELOW)
    mind_state.save_state(M.opts)
  end,

  add_inside_start = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.INSIDE_START)
    mind_state.save_state(M.opts)
  end,

  add_inside_end = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.INSIDE_END)
    mind_state.save_state(M.opts)
  end,

  delete = function(tree)
    M.delete_node_cursor(tree)
    mind_state.save_state(M.opts)
  end,

  rename = function(tree)
    M.conditionally_run_by_path(
      function() M.rename_node_cursor(tree) end,
      function(node) M.rename_node(tree, node) end
    )

    M.reset(tree)
    mind_state.save_state(M.opts)
  end,

  open_data = function(tree, data_dir)
    M.open_data_cursor(tree, data_dir)
    mind_state.save_state(M.opts)
  end,

  change_icon = function(tree)
    M.change_icon_node_cursor(tree)
    mind_state.save_state(M.opts)
  end,

  select = function(tree)
    M.toggle_select_node_cursor(tree)
  end,

  move_above = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.ABOVE)
    mind_state.save_state(M.opts)
  end,

  move_below = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.BELOW)
    mind_state.save_state(M.opts)
  end,

  move_inside_start = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.INSIDE_START)
    mind_state.save_state(M.opts)
  end,

  move_inside_end = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.INSIDE_END)
    mind_state.save_state(M.opts)
  end,

  node_at_path = function(tree)
    vim.ui.input({ prompt = 'Path: ', default = '/' }, function(input)
      if (input ~= nil) then
        M.enable_by_path(input, M.get_node_by_path(tree, input))
      end
    end)
  end,
}

M.KeymapSelector = {
  NORMAL = 'normal',
  SELECTION = 'selection',
  BY_PATH = 'by_path',
}

-- Keymaps.
M.keymaps = {
  selector = M.KeymapSelector.NORMAL,
  normal = {},
  selection = {},
  by_path = {},
}

local function init_keymaps()
  M.keymaps.normal = M.opts.keymaps.normal
  M.keymaps.selection = M.opts.keymaps.selection
  M.keymaps.by_path = M.opts.keymaps.by_path
end

local function set_keymap(selector)
  M.keymaps.selector = selector
end

local function get_keymap()
  return M.keymaps[M.keymaps.selector]
end

-- Precompute keymaps.
--
-- This function will scan the keymaps and will replace the command name with the real command function.
local function precompute_keymaps()
  for key, _ in pairs(M.keymaps.normal) do
    local cmd = commands[M.keymaps.normal[key]]

    if (cmd ~= nil) then
      M.keymaps.normal[key] = cmd
    end
  end

  for key, _ in pairs(M.keymaps.selection) do
    local cmd = commands[M.keymaps.selection[key]]

    if (cmd ~= nil) then
      M.keymaps.selection[key] = cmd
    end
  end

  for key, _ in pairs(M.keymaps.by_path) do
    local cmd = commands[M.keymaps.by_path[key]]

    if (cmd ~= nil) then
      M.keymaps.by_path[key] = cmd
    end
  end
end

-- Path selector.
--
-- When the path selector is set, we use the node as source of truth.
M.ByPath = {
  path = nil,
  node = nil,
}

M.enable_by_path = function(path, node)
  if (node == nil) then
    notify(string.format('no %s found', path), vim.log.levels.ERROR)
    return
  end

  notify('node by path ' .. path)
  M.ByPath.path = path
  M.ByPath.node = node

  set_keymap(M.KeymapSelector.BY_PATH)
end

-- Reset by path.
local function reset_by_path()
  M.ByPath.path = nil
  M.ByPath.node = nil
end

-- Run a function that either works with the cursor or a by-path node, depending on whether a by-path is set.
M.conditionally_run_by_path = function(with_cursor, with_node)
  if (M.ByPath.node == nil) then
    with_cursor()
  else
    with_node(M.ByPath.node)
  end
end

-- Reset keymaps and modes.
M.reset = function(tree)
  set_keymap(M.KeymapSelector.NORMAL)

  if (tree.selected ~= nil) then
    tree.selected.node.is_selected = nil
    tree.selected = nil
  end

  reset_by_path()
end

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', require'mind.defaults', opts or {})
  print('default path', M.opts.persistence.state_path)

  -- load tree state
  mind_state.load_state(M.opts)

  -- keymaps
  init_keymaps()
  precompute_keymaps()
end

M.open_main = function()
  M.wrap_main_tree_fn(function(tree) M.open_tree(tree, M.opts.persistence.data_dir) end)
end

M.open_project = function(use_global)
  M.wrap_project_tree_fn(function(tree) M.open_tree(tree, get_project_data_dir()) end, false, nil, use_global)
end

-- Move a node at a given cursor position.
M.selected_move = function(tree, i, move_dir)
  if (tree.selected == nil) then
    notify('cannot move; no selected node', vim.log.levels.WARN)
    M.unselect_node(tree)
    return
  end

  local parent, node = M.get_node_and_parent_by_nb(tree, i)

  if (parent == nil) then
    notify('cannot move root', vim.log.levels.ERROR)
    M.unselect_node(tree)
    return
  end

  if (node == nil) then
    notify('cannot move: wrong destination', vim.log.levels.ERROR)
    M.unselect_node(tree)
    return
  end

  -- if we move in the same tree, we can optimize
  if (parent == tree.selected.parent) then
    -- compute the index of the nodes to move
    local node_i
    local selected_i
    for k, child in ipairs(parent.children) do
      if (child == node) then
        node_i = k
      elseif (child == tree.selected.node) then
        selected_i = k
      end

      if (node_i ~= nil and selected_i ~= nil) then
        break
      end
    end

    if (node_i == nil or selected_i == nil) then
      -- same node; aborting
      M.unselect_node(tree)
      return
    end

    if (move_dir == M.MoveDir.BELOW) then
      move_source_target_same_tree(parent, selected_i, node_i + 1)
    elseif (move_dir == M.MoveDir.ABOVE) then
      move_source_target_same_tree(parent, selected_i, node_i)
    else
      -- we move inside, so first remove the node
      remove_node(parent, selected_i)

      if (move_dir == M.MoveDir.INSIDE_START) then
        insert_node(node, 1, tree.selected.node)
      elseif (move_dir == M.MoveDir.INSIDE_END) then
        insert_node(node, -1, tree.selected.node)
      end
    end
  else
    -- first, remove the node in its parent
    local selected_i = find_parent_index(tree.selected.parent, tree.selected.node)
    remove_node(tree.selected.parent, selected_i)

    -- then insert the previously deleted node in the new tree
    local node_i = find_parent_index(parent, node)

    if (move_dir == M.MoveDir.BELOW) then
      insert_node(parent, node_i + 1, tree.selected.node)
    elseif (move_dir == M.MoveDir.ABOVE) then
      insert_node(parent, node_i, tree.selected.node)
    elseif (move_dir == M.MoveDir.INSIDE_START) then
      insert_node(node, 1, tree.selected.node)
    elseif (move_dir == M.MoveDir.INSIDE_END) then
      insert_node(node, -1, tree.selected.node)
    end
  end

  M.unselect_node(tree)
end

M.selected_move_cursor = function(tree, move_dir)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  M.selected_move(tree, line, move_dir)
end

return M
