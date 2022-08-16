-- User-facing available commands.

local M = {}

local mind_data = require'mind.data'
local mind_keymap = require'mind.keymap'
local mind_node = require'mind.node'
local mind_state = require'mind.state'
local mind_ui = require'mind.ui'
local notify = require'mind.notify'.notify

M.commands = {
  toggle_node = function(tree, _, opts)
    M.toggle_node_cursor(tree, opts)
    mind_state.save_state(opts)
  end,

  quit = function(tree, _, opts)
    M.reset()
    M.close(tree, opts)
  end,

  add_above = function(tree, _, opts)
    M.create_node_cursor(tree, mind_node.MoveDir.ABOVE, opts)
    mind_state.save_state(opts)
  end,

  add_below = function(tree, _, opts)
    M.create_node_cursor(tree, mind_node.MoveDir.BELOW, opts)
    mind_state.save_state(opts)
  end,

  add_inside_start = function(tree, _, opts)
    M.create_node_cursor(tree, mind_node.MoveDir.INSIDE_START, opts)
    mind_state.save_state(opts)
  end,

  add_inside_end = function(tree, _, opts)
    M.create_node_cursor(tree, mind_node.MoveDir.INSIDE_END, opts)
    mind_state.save_state(opts)
  end,

  delete = function(tree, _, opts)
    M.delete_node_cursor(tree, opts)
    mind_state.save_state(opts)
  end,

  rename = function(tree, _, opts)
    M.rename_node_cursor(tree, opts)
    M.reset()
    mind_state.save_state(opts)
  end,

  open_data = function(tree, data_dir, opts)
    M.open_data_cursor(tree, data_dir, opts)
    mind_state.save_state(opts)
  end,

  change_icon = function(tree, _, opts)
    M.change_icon_cursor(tree, opts)
    mind_state.save_state(opts)
  end,

  select = function(tree, _, opts)
    M.toggle_select_node_cursor(tree, opts)
  end,

  select_path = function(tree, _, opts)
    M.select_node_path(tree, opts)
  end,

  move_above = function(tree, _, opts)
    M.move_node_selected_cursor(tree, mind_node.MoveDir.ABOVE, opts)
    mind_state.save_state(opts)
  end,

  move_below = function(tree, _, opts)
    M.move_node_selected_cursor(tree, mind_node.MoveDir.BELOW, opts)
    mind_state.save_state(opts)
  end,

  move_inside_start = function(tree, _, opts)
    M.move_node_selected_cursor(tree, mind_node.MoveDir.INSIDE_START, opts)
    mind_state.save_state(opts)
  end,

  move_inside_end = function(tree, _, opts)
    M.move_node_selected_cursor(tree, mind_node.MoveDir.INSIDE_END, opts)
    mind_state.save_state(opts)
  end,
}

-- Open the data file associated with a node.
--
-- If it doesn’t exist, create it first.
M.open_data = function(tree, node, directory, opts)
  local data = node.data
  if (data == nil) then
    local contents = string.format(opts.edit.data_header, node.contents[1].text)
    local should_expand = tree.type ~= mind_node.TreeType.LOCAL_ROOT

    data = mind_data.new_data_file(
      directory,
      node.contents[1].text .. opts.edit.data_extension,
      contents,
      should_expand
    )

    if (data == nil) then
      return
    end

    node.data = data
    mind_ui.render(tree, 0, opts)
  end

  local winnr = require('window-picker').pick_window()

  if (winnr == nil) then
    notify('cannot pick window; please install s1n7ax/nvim-window-picker')
    return
  end

  vim.api.nvim_set_current_win(winnr)
  vim.api.nvim_cmd({ cmd = 'e', args = { data } }, {})
end

-- Open the data file associated with a node for the given line.
--
-- If it doesn’t exist, create it first.
M.open_data_line = function(tree, line, directory, opts)
  local node = mind_node.get_node_by_line(tree, line)

  if (node == nil) then
    notify('cannot open data; no node', vim.log.levels.ERROR)
    return
  end

  M.open_data(tree, node, directory, opts)
end

-- Open the data file associated with the node under the cursor.
M.open_data_cursor = function(tree, directory, opts)
  mind_ui.with_cursor(function(line)
    M.open_data_line(tree, line, directory, opts)
  end)
end

-- Add a node as child of another node.
M.create_node = function(tree, grand_parent, parent, node, dir, opts)
  if (dir == mind_node.MoveDir.INSIDE_START) then
    mind_node.insert_node(parent, 1, node)
  elseif (dir == mind_node.MoveDir.INSIDE_END) then
    mind_node.insert_node(parent, -1, node)
  elseif (grand_parent ~= nil) then
    local index = mind_node.find_parent_index(grand_parent, parent)

    if (dir == mind_node.MoveDir.ABOVE) then
      mind_node.insert_node(grand_parent, index, node)
    elseif (dir == mind_node.MoveDir.BELOW) then
      mind_node.insert_node(grand_parent, index + 1, node)
    end
  else
    notify('forbidden node creation', vim.log.levels.WARN)
    return
  end

  mind_ui.render(tree, 0, opts)
end

-- Add a node as child of another node on the given line.
M.create_node_line = function(tree, line, name, dir, opts)
  local grand_parent, parent = mind_node.get_node_and_parent_by_line(tree, line)

  if (parent == nil) then
    notify('cannot create node on current line; no node', vim.log.levels.ERROR)
    return
  end

  local node = mind_node.new_node(name, nil)

  M.create_node(tree, grand_parent, parent, node, dir, opts)
end

-- Ask the user for input and the node in the tree at the given direction.
M.create_node_cursor = function(tree, dir, opts)
  mind_ui.with_cursor(function(line)
    mind_ui.with_input('Node name: ', nil, function(input)
      M.create_node_line(tree, line, input, dir, opts)
    end)
  end)
end

-- Delete a node on a given line in the tree.
M.delete_node_line = function(tree, line, opts)
  local parent, node = mind_node.get_node_and_parent_by_line(tree, line)

  if (node == nil) then
    notify('no node to delete', vim.log.levels.ERROR)
    return
  end

  if (parent == nil) then
    notify('cannot delete a node without parent', vim.log.levels.ERROR)
    return
  end

  local index = mind_node.find_parent_index(parent, node)

  mind_ui.with_confirmation(string.format("Delete '%s'?", node.contents[1].text), function()
    mind_node.delete_node(parent, index)
    mind_ui.render(tree, 0, opts)
  end)
end

-- Delete the node under the cursor.
M.delete_node_cursor = function(tree, opts)
  mind_ui.with_cursor(function(line)
    M.delete_node_line(tree, line, opts)
  end)
end

-- Rename a node.
M.rename_node = function(tree, node, opts)
  mind_ui.with_input('Rename node: ', node.contents[1].text, function(input)
    node.contents[1].text = input
    mind_ui.render(tree, 0, opts)
  end)
end

-- Rename a node at a given line.
M.rename_node_line = function(tree, line, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.rename_node(tree, node, opts)
end

-- Rename the node under the cursor.
M.rename_node_cursor = function(tree, opts)
  mind_ui.with_cursor(function(line)
    M.rename_node_line(tree, line, opts)
  end)
end

-- Change the icon of a node.
M.change_icon = function(tree, node, opts)
  mind_ui.with_input('Change icon: ', node.icon, function(input)
    if input == ' ' then
      input = nil
    end

    node.icon = input
    mind_ui.render(tree, 0, opts)
  end)
end

-- Change the icon of the node at a given line.
M.change_icon_line = function(tree, line, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.change_icon(tree, node, opts)
end

-- Change the icon of the node under the cursor.
M.change_icon_cursor = function(tree, opts)
  mind_ui.with_cursor(function(line)
    M.change_icon_line(tree, line, opts)
  end)
end

-- Select a node.
M.select_node = function(tree, parent, node, opts)
  -- ensure we unselect anything that would be currently selected
  M.unselect_node(tree, opts)

  node.is_selected = true
  M.selected = { parent = parent, node = node }

  mind_keymap.set_keymap(mind_keymap.KeymapSelector.SELECTION)
  mind_ui.render(tree, 0, opts)
end

-- Select a node at the given line.
M.select_node_line = function(tree, line, opts)
  local parent, node = mind_node.get_node_and_parent_by_line(tree, line)
  M.select_node(tree, parent, node, opts)
end

-- Select a node by path.
M.select_node_path = function(tree, opts)
  mind_ui.with_input('Path: /', nil, function(input)
    local parent, node = mind_node.get_node_by_path(tree, '/' .. input)

    if node ~= nil then
      M.select_node(tree, parent, node, opts)
    end
  end)
end

-- Unselect any selected node in the tree.
M.unselect_node = function(tree, opts)
  if (M.selected ~= nil) then
    M.selected.node.is_selected = nil
    M.selected = nil

    mind_keymap.set_keymap(mind_keymap.KeymapSelector.NORMAL)
    mind_ui.render(tree, 0, opts)
  end
end

-- Toggle between cursor selected and unselected node.
--
-- This works by selecting a node under the cursor if nothing is selected or if something else is selected. To select
-- something, you need to toggle the currently selected node.
M.toggle_select_node_cursor = function(tree, opts)
  mind_ui.with_cursor(function(line)
    if (M.selected ~= nil) then
      local node = mind_node.get_node_by_line(tree, line)
      if (node == M.selected.node) then
        M.unselect_node(tree, opts)
      else
        M.unselect_node(tree, opts)
        M.select_node_line(tree, line, opts)
      end
    else
      M.select_node_line(tree, line, opts)
    end
  end)
end

-- Move a node into another node.
M.move_node = function(
  tree,
  source_parent,
  source_node,
  target_parent,
  target_node,
  dir,
  opts
)
  if (source_node == nil) then
    notify('cannot move; no source node', vim.log.levels.WARN)
    return
  end

  if (target_node == nil) then
    notify('cannot move; no target node', vim.log.levels.WARN)
    return
  end

  -- if we move in the same tree, we can optimize
  if (source_parent == target_parent) then
    -- compute the index of the nodes to move
    local source_i
    local target_i
    for k, child in ipairs(source_parent.children) do
      if (child == target_node) then
        target_i = k
      elseif (child == source_node) then
        source_i = k
      end

      if (target_i ~= nil and source_i ~= nil) then
        break
      end
    end

    if (target_i == nil or source_i == nil) then
      -- trying to move inside itsefl; abort
      M.unselect_node(tree, opts)
      return
    end

    if (target_i == source_i) then
      -- same node; aborting
      notify('not moving; source and target are the same node')
      M.unselect_node(tree, opts)
      return
    end

    if (dir == mind_node.MoveDir.BELOW) then
      mind_node.move_source_target_same_tree(
        source_parent,
        source_i,
        target_i + 1
      )
    elseif (dir == mind_node.MoveDir.ABOVE) then
      mind_node.move_source_target_same_tree(source_parent, source_i, target_i)
    else
      -- we move inside, so first remove the node
      mind_node.delete_node(source_parent, source_i)

      if (dir == mind_node.MoveDir.INSIDE_START) then
        mind_node.insert_node(target_node, 1, source_node)
      elseif (dir == mind_node.MoveDir.INSIDE_END) then
        mind_node.insert_node(target_node, -1, source_node)
      end
    end
  else
    -- first, remove the node in its parent
    local source_i = mind_node.find_parent_index(source_parent, source_node)
    mind_node.delete_node(source_parent, source_i)

    -- then insert the previously deleted node in the new tree
    local target_i = mind_node.find_parent_index(target_parent, target_node)

    if (dir == mind_node.MoveDir.BELOW) then
      mind_node.insert_node(target_parent, target_i + 1, source_node)
    elseif (dir == mind_node.MoveDir.ABOVE) then
      mind_node.insert_node(target_parent, target_i, source_node)
    elseif (dir == mind_node.MoveDir.INSIDE_START) then
      mind_node.insert_node(target_node, 1, source_node)
    elseif (dir == mind_node.MoveDir.INSIDE_END) then
      mind_node.insert_node(target_node, -1, source_node)
    end
  end

  M.unselect_node(tree, opts)
end

-- Move a selected node into a node at the given line.
M.move_node_selected_line = function(tree, line, dir, opts)
  if (M.selected == nil) then
    notify('cannot move; no selected node', vim.log.levels.ERROR)
    M.unselect_node(tree, opts)
    return
  end

  local parent, node = mind_node.get_node_and_parent_by_line(tree, line)

  if (parent == nil) then
    notify('cannot move root', vim.log.levels.ERROR)
    M.unselect_node(tree, opts)
    return
  end

  M.move_node(
    tree,
    M.selected.parent,
    M.selected.node,
    parent,
    node,
    dir,
    opts
  )
end

-- Move a selected node into the node under the cursor.
M.move_node_selected_cursor = function(tree, dir, opts)
  mind_ui.with_cursor(function(line)
    M.move_node_selected_line(tree, line, dir, opts)
  end)
end

-- Toggle (expand / collapse) a node.
M.toggle_node = function(tree, node, opts)
  node.is_expanded = not node.is_expanded
  mind_ui.render(tree, 0, opts)
end

-- Toggle (expand / collapse) a node at a given line.
M.toggle_node_line = function(tree, line, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.toggle_node(tree, node, opts)
end

-- Toggle (expand / collapse) the node under the cursor.
M.toggle_node_cursor = function(tree, opts)
  mind_ui.with_cursor(function(line)
    M.toggle_node_line(tree, line, opts)
  end)
end

-- Open and display a tree in a new window.
M.open_tree = function(tree, data_dir, opts)
  -- window
  vim.api.nvim_cmd({ cmd = 'vsp'}, {})
  vim.api.nvim_cmd({ cmd = 'wincmd', args = { 'H' } }, {})
  vim.api.nvim_win_set_width(0, opts.ui.width)

  -- buffer
  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(bufnr, 'mind')
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'mind')
  vim.api.nvim_win_set_option(0, 'nu', false)

  -- tree
  mind_ui.render(tree, bufnr, opts)

  -- keymaps
  mind_keymap.insert_keymaps(bufnr, tree, data_dir, opts)
end

-- Close the tree.
M.close = function(tree, opts)
  M.unselect_node(tree, opts)
  vim.api.nvim_buf_delete(0, { force = true })
end

-- Reset keymaps and modes.
M.reset = function()
  mind_keymap.set_keymap(mind_keymap.KeymapSelector.NORMAL)

  if (M.selected ~= nil) then
    M.selected.node.is_selected = nil
    M.selected = nil
  end
end

-- Precompute commands.
--
-- This function will scan the keymaps and will replace the command name with the real command function.
M.precompute_commands = function()
  for key, _ in pairs(mind_keymap.keymaps.normal) do
    local cmd = M.commands[mind_keymap.keymaps.normal[key]]

    if (cmd ~= nil) then
      mind_keymap.keymaps.normal[key] = cmd
    end
  end

  for key, _ in pairs(mind_keymap.keymaps.selection) do
    local cmd = M.commands[mind_keymap.keymaps.selection[key]]

    if (cmd ~= nil) then
      mind_keymap.keymaps.selection[key] = cmd
    end
  end
end

return M
