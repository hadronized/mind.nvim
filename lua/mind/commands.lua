-- User-facing available commands.

local M = {}

local mind_data = require'mind.data'
local mind_indexing = require'mind.indexing'
local mind_keymap = require'mind.keymap'
local mind_node = require'mind.node'
local mind_ui = require'mind.ui'
local notify = require'mind.notify'.notify

M.commands = {
  toggle_node = function(args)
    M.toggle_node_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  toggle_parent = function(args)
    M.toggle_node_parent_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  quit = function()
    M.unselect_node()
    M.close()
  end,

  add_above = function(args)
    M.create_node_cursor(args.get_tree(), mind_node.MoveDir.ABOVE, args.save_tree, args.opts)
  end,

  add_below = function(args)
    M.create_node_cursor(args.get_tree(), mind_node.MoveDir.BELOW, args.save_tree, args.opts)
  end,

  add_inside_start = function(args)
    M.create_node_cursor(args.get_tree(), mind_node.MoveDir.INSIDE_START, args.save_tree, args.opts)
  end,

  add_inside_end = function(args)
    M.create_node_cursor(args.get_tree(), mind_node.MoveDir.INSIDE_END, args.save_tree, args.opts)
  end,

  add_inside_end_index = function(args)
    M.create_node_index(args.get_tree(), mind_node.MoveDir.INSIDE_END, args.save_tree, args.opts)
  end,

  delete = function(args)
    M.delete_node_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  delete_file = function(args)
    M.delete_data_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  rename = function(args)
    M.rename_node_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  open_data = function(args)
    M.open_data_cursor(args.get_tree(), args.data_dir, args.save_tree, args.opts)
  end,

  open_data_index = function(args)
    M.open_data_index(args.get_tree(), args.data_dir, args.save_tree, args.opts)
  end,

  copy_node_link = function(args)
    M.copy_node_link_cursor(args.get_tree(), nil, args.opts)
  end,

  copy_node_link_index = function(args)
    M.copy_node_link_index(args.get_tree(), nil, args.opts)
  end,

  make_url = function(args)
    M.make_url_node_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  change_icon = function(args)
    M.change_icon_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  change_icon_menu = function(args)
    M.change_icon_menu_cursor(args.get_tree(), args.save_tree, args.opts)
  end,

  select = function(args)
    M.toggle_select_node_cursor(args.get_tree(), args.opts)
  end,

  select_path = function(args)
    M.select_node_path(args.get_tree(), args.opts)
  end,

  move_above = function(args)
    M.move_node_selected_cursor(args.get_tree(), mind_node.MoveDir.ABOVE, args.save_tree, args.opts)
  end,

  move_below = function(args)
    M.move_node_selected_cursor(args.get_tree(), mind_node.MoveDir.BELOW, args.save_tree, args.opts)
  end,

  move_inside_start = function(args)
    M.move_node_selected_cursor(args.get_tree(), mind_node.MoveDir.INSIDE_START, args.save_tree, args.opts)
  end,

  move_inside_end = function(args)
    M.move_node_selected_cursor(args.get_tree(), mind_node.MoveDir.INSIDE_END, args.save_tree, args.opts)
  end,
}

-- Open the data file associated with a node.
--
-- If it doesn’t exist, create it first.
M.open_data = function(tree, node, directory, save_tree, opts)
  if node.url then
    vim.fn.system(string.format('%s "%s"', opts.ui.url_open, node.url))
    return
  end

  local data = node.data
  if (data == nil) then
    local contents = string.format(opts.edit.data_header, node.contents[1].text)
    local should_expand = tree.type ~= mind_node.TreeType.LOCAL_ROOT

    data = mind_data.new_data_file(
      directory,
      node.contents[1].text,
      opts.edit.data_extension,
      contents,
      should_expand
    )

    if (data == nil) then
      return
    end

    node.data = data
    mind_ui.rerender(tree, opts)
    save_tree()
  end

  -- list all the visible windows and filter the one that have a nofile (likely to be the mind, but it could also be
  -- file browser or something)
  local winnr
  for _, tabpage_winnr in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local bufnr = vim.api.nvim_win_get_buf(tabpage_winnr)
    local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')

    if buftype == '' then
      winnr = tabpage_winnr
      break
    end
  end

  -- pick the first window in the list; if it’s empty, we open a new one
  if winnr == nil then
    vim.api.nvim_exec('rightb vsp ' .. data, false)
  else
    vim.api.nvim_set_current_win(winnr)
    vim.api.nvim_exec('e ' .. data, false)
  end

    if opts.ui.close_on_file_open == true then
        M.close()
    end
end

-- Delete the data file associated with a node.
--
-- If it doesn’t exist, does nothing.
M.delete_data = function(tree, node, save_tree, opts)
  if (node.data == nil) then
    notify('no files associated to this node', vim.log.levels.ERROR)
    return
  else
    mind_ui.with_confirmation("Delete file?", function()
      local file_path = node.data
      mind_data.delete_data_file(file_path)
      node.data = nil
      mind_ui.rerender(tree, opts)
      save_tree()
      notify(string.format("file '%s' deleted", file_path), vim.log.levels.INFO)
    end)
  end
end

-- Open the data file associated with a node for the given line.
--
-- If it doesn’t exist, create it first.
M.open_data_line = function(tree, line, directory, save_tree, opts)
  local node = mind_node.get_node_by_line(tree, line)

  if (node == nil) then
    notify('cannot open data; no node', vim.log.levels.ERROR)
    return
  end

  M.open_data(tree, node, directory, save_tree, opts)
end

-- Open the data file associated with the node under the cursor.
M.open_data_cursor = function(tree, directory, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.open_data_line(tree, line, directory, save_tree, opts)
  end)
end

-- Delete the data file associated with a node for the given line.
--
-- If it doesn’t exist, create it first.
M.delete_data_line = function(tree, line, save_tree, opts)
  local node = mind_node.get_node_by_line(tree, line)

  if (node == nil) then
    notify('cannot delete data; no node', vim.log.levels.ERROR)
    return
  end

  M.delete_data(tree, node, save_tree, opts)
end

-- Deletes the data file associated with the node under the cursor.
M.delete_data_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.delete_data_line(tree, line, save_tree, opts)
  end)
end

-- Open the data file associated with the node in the index
M.open_data_index = function(tree, directory, save_tree, opts)
  mind_indexing.search_index(
    tree,
    'Open data / URL',
    -- filter function
    function(node)
      return opts.tree.automatic_data_creation or node.data ~= nil or node.url ~= nil
    end,
    -- sink function
    function(item)
      M.open_data(tree, item.node, directory, save_tree, opts)
    end,
    opts
  )
end

-- Get the “link” of a node and put it in the provided register.
--
-- If the node is a data node, get the path of the associated data file.
-- If the node is a URL node, get the URL.
--
-- If `reg` is omitted, the link is copied to the "" register.
M.copy_node_link = function(node, reg, opts)
  local link = node.data or node.url

  if link ~= nil then
    notify('link was copied')
    vim.fn.setreg(reg or '"', string.format(opts.edit.copy_link_format or '%s', link))
  end
end

-- Get the “link” of a node on the given line.
M.copy_node_link_line = function(tree, line, reg, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.copy_node_link(node, reg, opts)
end

-- Get the “link” of a node under the cursor.
M.copy_node_link_cursor = function(tree, reg, opts)
  mind_ui.with_cursor(function(line)
    M.copy_node_link_line(tree, line, reg, opts)
  end)
end

-- Get the “link” of a node by doing an index search.
M.copy_node_link_index = function(tree, reg, opts)
  mind_indexing.search_index(
    tree,
    'Get a node link',
    -- filter function
    function(node)
      return node.data ~= nil or node.url ~= nil
    end,
    -- sink function
    function(item)
      M.copy_node_link(item.node, reg, opts)
    end,
    opts
  )
end

-- Turn a node into a URL node.
--
-- For this to work, the node must not have any data associated with it.
M.make_url_node = function(tree, node, save_tree, opts)
  if node.data ~= nil then
    notify('cannot create URL node: data present', vim.log.levels.ERROR)
    return
  end

  mind_ui.with_input('URL: ', 'https://', function(input)
    node.url = input
    save_tree()
    mind_ui.rerender(tree, opts)
  end)
end

-- Turn the node on the given line a URL node.
M.make_url_node_line = function(tree, line, save_tree, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.make_url_node(tree, node, save_tree, opts)
end

-- Turn the node under the cursor a URL node.
M.make_url_node_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.make_url_node_line(tree, line, save_tree, opts)
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

  mind_ui.rerender(tree, opts)
end

-- Add a node as child of another node on the given line.
M.create_node_line = function(tree, line, name, dir, save_tree, opts)
  local grand_parent, parent = mind_node.get_node_and_parent_by_line(tree, line)

  if (parent == nil) then
    notify('cannot create node on current line; no node', vim.log.levels.ERROR)
    return
  end

  local node = mind_node.new_node(name, nil)

  M.create_node(tree, grand_parent, parent, node, dir, opts)
  save_tree()
end

-- Ask the user for input and the node in the tree at the given direction.
M.create_node_cursor = function(tree, dir, save_tree, opts)
  mind_ui.with_cursor(function(line)
    mind_ui.with_input('Node name: ', nil, function(input)
      M.create_node_line(tree, line, input, dir, save_tree, opts)
    end)
  end)
end

-- Use the index to locate the node where to add anothere node in.
M.create_node_index = function(tree, dir, save_tree, opts)
  mind_indexing.search_index(
    tree,
    'Pick a node to create a new node in',
    -- filter function
    nil,
    -- sink function
    function(item)
      mind_ui.with_input('Node name: ', nil, function(input)
        local node = mind_node.new_node(input)
        M.create_node(tree, item.parent, item.node, node, dir, opts)
        save_tree()
      end)
    end,
    opts
  )
end

-- Delete a node on a given line in the tree.
M.delete_node_line = function(tree, line, save_tree, opts)
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
    mind_ui.rerender(tree, opts)
    save_tree()
  end)
end

-- Delete the node under the cursor.
M.delete_node_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.delete_node_line(tree, line, save_tree, opts)
  end)
end

-- Rename a node.
M.rename_node = function(tree, node, save_tree, opts)
  mind_ui.with_input('Rename node: ', node.contents[1].text, function(input)
    node.contents[1].text = input
    M.unselect_node()
    mind_ui.rerender(tree, opts)
    save_tree()
  end)
end

-- Rename a node at a given line.
M.rename_node_line = function(tree, line, save_tree, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.rename_node(tree, node, save_tree, opts)
end

-- Rename the node under the cursor.
M.rename_node_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.rename_node_line(tree, line, save_tree, opts)
  end)
end

-- Change the icon of a node.
M.change_icon = function(tree, node, save_tree, opts)
  mind_ui.with_input('Change icon: ', node.icon, function(input)
    if input == ' ' then
      input = nil
    end

    node.icon = input
    mind_ui.rerender(tree, opts)
    save_tree()
  end)
end

-- Change the icon of the node at a given line.
M.change_icon_line = function(tree, line, save_tree, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.change_icon(tree, node, save_tree, opts)
end

-- Change the icon of the node under the cursor.
M.change_icon_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.change_icon_line(tree, line, save_tree, opts)
  end)
end

-- Change the icon of a node by selecting through the list of preset icons.
M.change_icon_menu = function(tree, node, save_tree, opts)
  local prompt = string.format('Pick an icon for %s', node.contents[1].text)
  local format_item = function(item)
    return string.format('%s: %s', item[1], item[2])
  end

  vim.ui.select(
    opts.ui.icon_preset,
    {
      prompt = prompt,
      format_item = format_item
    },
    function(item)
      if item ~= nil then
        node.icon = item[1]
        save_tree()
        mind_ui.rerender(tree, opts)
      end
    end
  )
end

-- Change the icon of the node at a given line through the list of preset icons.
M.change_icon_menu_line = function(tree, line, save_tree, opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.change_icon_menu(tree, node, save_tree, opts)
end

-- Change the icon of the node under the cursor through the list of preset icons.
M.change_icon_menu_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.change_icon_menu_line(tree, line, save_tree, opts)
  end)
end

-- Select a node.
M.select_node = function(tree, parent, node, opts)
  -- ensure we unselect anything that would be currently selected
  M.unselect_node()

  node.is_selected = true
  M.selected = { parent = parent, node = node }

  mind_keymap.set_keymap(mind_keymap.KeymapSelector.SELECTION)
  mind_ui.rerender(tree, opts)
end

-- Select a node at the given line.
M.select_node_line = function(tree, line, opts)
  local parent, node = mind_node.get_node_and_parent_by_line(tree, line)
  M.select_node(tree, parent, node, opts)
end

-- Select a node by path.
M.select_node_path = function(tree, opts)
  mind_ui.with_input('Path: /', nil, function(input)
    local parent, node = mind_node.get_node_by_path(
      tree,
      '/' .. input,
      opts.tree.automatic_creation
    )

    if node ~= nil then
      M.select_node(tree, parent, node, opts)
    end
  end)
end

-- Unselect any selected node in the tree.
M.unselect_node = function()
  if (M.selected ~= nil) then
    M.selected.node.is_selected = nil
    M.selected = nil

    mind_keymap.set_keymap(mind_keymap.KeymapSelector.NORMAL)
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
        M.unselect_node()
        mind_ui.rerender(tree, opts)
      else
        M.unselect_node()
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
      M.unselect_node()
      mind_ui.rerender(tree, opts)
      return
    end

    if (target_i == source_i) then
      -- same node; aborting
      notify('not moving; source and target are the same node')
      M.unselect_node()
      mind_ui.rerender(tree, opts)
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

  M.unselect_node()
  mind_ui.rerender(tree, opts)
end

-- Move a selected node into a node at the given line.
M.move_node_selected_line = function(tree, line, dir, save_tree, opts)
  if (M.selected == nil) then
    notify('cannot move; no selected node', vim.log.levels.ERROR)
    M.unselect_node()
    mind_ui.rerender(tree, opts)
    return
  end

  local parent, node = mind_node.get_node_and_parent_by_line(tree, line)

  if (parent == nil) then
    notify('cannot move root', vim.log.levels.ERROR)
    M.unselect_node()
    mind_ui.rerender(tree, opts)
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

  save_tree()
end

-- Move a selected node into the node under the cursor.
M.move_node_selected_cursor = function(tree, dir, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.move_node_selected_line(tree, line, dir, save_tree, opts)
  end)
end

-- Toggle (expand / collapse) a node.
M.toggle_node = function(tree, node, save_tree, opts)
  node.is_expanded = not node.is_expanded
  mind_ui.rerender(tree, opts)
  save_tree()
end

-- Toggle (expand / collapse) a node at a given line.
M.toggle_node_line = function(tree, line, save_tree,opts)
  local node = mind_node.get_node_by_line(tree, line)
  M.toggle_node(tree, node, save_tree, opts)
end

-- Toggle (expand / collapse) the node under the cursor.
M.toggle_node_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    M.toggle_node_line(tree, line, save_tree, opts)
  end)
end

-- Toggle (expand / collapse) the node’s parent under the cursor, if any.
M.toggle_node_parent_cursor = function(tree, save_tree, opts)
  mind_ui.with_cursor(function(line)
    local parent, _ = mind_node.get_node_and_parent_by_line(tree, line)

    if parent ~= nil then
      M.toggle_node(tree, parent, save_tree, opts)
    end
  end)
end

-- Open and display a tree in a new window.
M.open_tree = function(get_tree, data_dir, save_tree, opts)
  -- window
  local bufnr = mind_ui.open_window(opts)

  -- ensure that we close the tree if the window gets closed
  local id
  id = vim.api.nvim_create_autocmd(
    { 'WinClosed' },
    {
      buffer = bufnr,
      callback = function()
        vim.api.nvim_del_autocmd(id)
        M.close()
      end
    }
  )

  -- tree
  mind_ui.render(get_tree(), bufnr, opts)

  -- keymaps
  mind_keymap.insert_keymaps(bufnr, get_tree, data_dir, save_tree, opts)
end

-- Close the tree.
M.close = function()
  M.unselect_node()

  -- close the buffer if open
  if mind_ui.render_cache and mind_ui.render_cache.bufnr then
    vim.api.nvim_buf_delete(mind_ui.render_cache.bufnr, { force = true })
  end

  -- reset the cache
  mind_ui.render_cache = {}
end

-- Toggle the tree
M.toggle = function(get_tree, data_dir, save_tree, opts)
  if mind_ui.render_cache and mind_ui.render_cache.bufnr then
    -- close the buffer if open
    M.close()
  else
    -- open the buffer if closed
    M.open_tree(get_tree, data_dir, save_tree, opts)
  end
end

-- Precompute commands.
--
-- This function will scan the keymaps and will replace the command name with the real command function, if the command
-- name is a string.
M.precompute_commands = function()
  for key, c in pairs(mind_keymap.keymaps.normal) do
    if type(c) == 'string' then
      local cmd = M.commands[mind_keymap.keymaps.normal[key]]

      if (cmd ~= nil) then
        mind_keymap.keymaps.normal[key] = cmd
      end
    end
  end

  for key, c in pairs(mind_keymap.keymaps.selection) do
    if type(c) == 'string' then
      local cmd = M.commands[mind_keymap.keymaps.selection[key]]

      if (cmd ~= nil) then
        mind_keymap.keymaps.selection[key] = cmd
      end
    end
  end
end

return M
