local path = require'plenary.path'

local M = {}

local function notify(msg, lvl)
  vim.notify(msg, lvl, { title = 'Mind', icon = '' })
end

-- FIXME: recursively ensure that the paths are created
-- FIXME: group settings by categories, like opts.ui.*, opts.fs.*, opts.edit.*, etc. etc.
local defaults = {
  -- state & data stuff
  state_path = '~/.local/share/mind.nvim/mind.json',
  data_dir = '~/.local/share/mind.nvim/data',

  -- edition stuff
  data_extension = '.md',
  data_header = '# %s',

  -- UI stuff
  width = 30,
  root_marker = ' ',
  local_marker = 'local',
  data_marker = '',
  selected_marker = '',

  -- highlight stuff
  hl_mark_closed = 'LineNr',
  hl_mark_open = 'LineNr',
  hl_node_root = 'Function',
  hl_node_leaf = 'String',
  hl_node_parent = 'Title',
  hl_modifier_local = 'Comment',
  hl_modifier_grey = 'Grey',
  hl_modifier_empty = 'CursorLineNr',
  hl_modifier_selected = 'Error',

  -- keybindings stuff
  keymaps = {
    normal = {
      ['<cr>'] = 'open_data',
      ['<tab>'] = 'toggle_node',
      I = 'add_inside_start',
      i = 'add_inside_end',
      d = 'delete',
      O = 'add_above',
      o = 'add_below',
      q = 'quit',
      r = 'rename',
      R = 'change_icon',
      x = 'select',
    },

    selection = {
      I = 'move_inside_start',
      i = 'move_inside_end',
      O = 'move_above',
      o = 'move_below',
      q = 'quit',
      x = 'select',
    },
  }
}

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
    M.save_state()
  end,

  quit = function(tree)
    M.close(tree)
  end,

  add_above = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.ABOVE)
    M.save_state()
  end,

  add_below = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.BELOW)
    M.save_state()
  end,

  add_inside_start = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.INSIDE_START)
    M.save_state()
  end,

  add_inside_end = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.INSIDE_END)
    M.save_state()
  end,

  delete = function(tree)
    M.delete_node_cursor(tree)
    M.save_state()
  end,

  rename = function(tree)
    M.rename_node_cursor(tree)
    M.save_state()
  end,

  open_data = function(tree, data_dir)
    M.open_data_cursor(tree, data_dir)
    M.save_state()
  end,

  change_icon = function(tree)
    M.change_icon_node_cursor(tree)
    M.save_state()
  end,

  select = function(tree)
    M.toggle_select_node_cursor(tree)
  end,

  move_above = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.ABOVE)
    M.save_state()
  end,

  move_below = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.BELOW)
    M.save_state()
  end,

  move_inside_start = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.INSIDE_START)
    M.save_state()
  end,

  move_inside_end = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.INSIDE_END)
    M.save_state()
  end,
}

M.KeymapSelector = {
  NORMAL = 'normal',
  SELECTION = 'selection',
}

-- Keymaps.
M.keymaps = {
  selector = M.KeymapSelector.NORMAL,
  normal = {},
  selection = {},
}

local function init_keymaps()
  M.keymaps.normal = M.opts.keymaps.normal
  M.keymaps.selection = M.opts.keymaps.selection
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
end

local function compute_hl(node)
  if (node.type == M.TreeType.ROOT) then
    return M.opts.hl_node_root
  elseif (node.type == M.TreeType.LOCAL_ROOT) then
    return M.opts.hl_node_root
  elseif (node.children ~= nil) then
    return M.opts.hl_node_parent
  else
    return M.opts.hl_node_leaf
  end
end

local function expand_opts_paths()
  M.opts.state_path = vim.fn.expand(M.opts.state_path)
  M.opts.data_dir = vim.fn.expand(M.opts.data_dir)
end

M.setup = function(opts)
  M.opts = setmetatable(opts or {}, {__index = defaults})

  expand_opts_paths()

  -- load tree state
  M.load_state()

  -- keymaps
  init_keymaps()
  precompute_keymaps()
end

-- Load the state.
--
-- If CWD has a .mind/, the projects part of the state is overriden with its contents. However, the main tree remains in
-- M.opts.state_path.
M.load_state = function()
  M.state = {
    -- Main tree, used for when no specific project is wanted.
    tree = {
      contents = {
        { text = 'Main' },
      },
      type = M.TreeType.ROOT,
      icon = M.opts.root_marker,
    },

    -- Per-project trees; this is a map from the CWD of projects to the actual tree for that project.
    projects = {},
  }

  -- Local tree, for local projects.
  M.local_tree = nil

  if (M.opts == nil or M.opts.state_path == nil) then
    notify('cannot load shit', 4)
    return
  end

  local file = io.open(M.opts.state_path, 'r')

  if (file == nil) then
    notify('no global state', 4)
  else
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
      notify('no local state', 4)
      M.local_tree = {
        contents = {
          { text = cwd:match('^.+/(.+)$') },
        },
        type = M.TreeType.LOCAL_ROOT,
        icon = M.opts.root_marker,
      }
    else
      local encoded = file:read()
      file:close()

      if (encoded ~= nil) then
        M.local_tree = vim.json.decode(encoded)
      end
    end
  end
end

-- Function run to cleanse a tree before saving (some data shouldn’t be saved).
local function pre_save()
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

M.save_state = function()
  if (M.opts == nil or M.opts.state_path == nil) then
    return
  end

  pre_save()

  local file = io.open(M.opts.state_path, 'w')

  if (file == nil) then
    notify(string.format('cannot save state at %s', M.opts.state_path), 4)
  else
    local encoded = vim.json.encode(M.state)
    file:write(encoded)
    file:close()
  end

  -- if there is a local state, we write the local project
  local cwd = vim.fn.getcwd()
  local local_mind = path:new(cwd, '.mind')
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

-- Create a new random file in a given directory.
--
-- Return the path to the created file, expanded if required.
local function new_data_file(dir, name, content, should_expand)
  local filename = vim.fn.strftime('%Y%m%d%H%M%S-') .. name
  local p = path:new(dir, filename)
  local file_path = (should_expand and p:expand()) or tostring(p)

  print('dir', dir)
  print('filename', filename)
  print('file_path', file_path)
  local file = io.open(file_path, 'w')

  if (file == nil) then
    notify('cannot open data file: ' .. file_path)
    return nil
  end

  file:write(content)
  file:close()

  return file_path
end

local function open_data(tree, i, dir)
  local node = M.get_node_by_nb(tree, i)

  if (node == nil) then
    notify('open_data nope', 4)
    return
  end

  local data = node.data
  if (data == nil) then
    local contents = string.format(M.opts.data_header, node.contents[1].text)
    local should_expand = tree.type ~= M.TreeType.LOCAL_ROOT
    print('should_expand', should_expand)
    data = new_data_file(dir, node.contents[1].text .. M.opts.data_extension, contents, should_expand)

    if (data == nil) then
      return
    end

    node.data = data
  end

  M.rerender(tree)

  local winnr = require('window-picker').pick_window()

  if (winnr ~= nil) then
    vim.api.nvim_set_current_win(winnr)
    vim.api.nvim_cmd({ cmd = 'e', args = { data } }, {})
  end
end

M.open_data_cursor = function(tree, data_dir)
  if (data_dir == nil) then
    notify('data directory not available', 4)
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  open_data(tree, line, data_dir)
end

M.Node = function(name, children)
  local contents = {
    { text = name }
  }
  return {
    contents = contents,
    is_expanded = false,
    children = children
  }
end

-- Wrap a function call expecting a tree by extracting from the state the right tree, depending on CWD.
--
-- The `save` argument will automatically save the state after the function is done, if set to `true`.
M.wrap_tree_fn = function(f, save)
  local cwd = vim.fn.getcwd()
  local project_tree = M.state.projects[cwd]

  if (project_tree == nil) then
    M.wrap_main_tree_fn(f, save)
  else
    M.wrap_project_tree_fn(f, save, project_tree)
  end
end

-- Wrap a function call expecting a tree with the main tree.
M.wrap_main_tree_fn = function(f, save)
  f(M.state.tree)

  if (save) then
    M.save_state()
  end
end

-- Wrap a function call expecting a project tree.
--
-- If the projec tree doesn’t exist, it is automatically created.
M.wrap_project_tree_fn = function(f, save, tree, use_global)
  if (tree == nil) then
    if (M.local_tree == nil or use_global) then
      local cwd = vim.fn.getcwd()
      tree = M.state.projects[cwd]

      if (tree == nil) then
        tree = {
          contents = {
            { text = cwd:match('^.+/(.+)$') },
          },
          type = M.TreeType.ROOT,
          icon = M.opts.root_marker,
        }
        M.state.projects[cwd] = tree
      end
    else
      tree = M.local_tree
    end
  end

  f(tree)

  if (save) then
    M.save_state()
  end
end

local function get_ith(parent, node, i)
  if (i == 0) then
    return parent, node, nil
  end

  i = i - 1

  if (node.children ~= nil and node.is_expanded) then
    for _, child in ipairs(node.children) do
      local p, n
      p, n, i = get_ith(node, child, i)

      if (n ~= nil) then
        return p, n, nil
      end
    end
  end

  return nil, nil, i
end

M.get_node_by_nb = function(tree, i)
  local _, node, _ = get_ith(nil, tree, i)
  return node
end

M.get_node_and_parent_by_nb = function(tree, i)
  local parent, node, _ = get_ith(nil, tree, i)
  return parent, node
end

-- Insert a node at index i in the given tree.
--
-- If i is negative, it starts after the end.
local function insert_node(tree, i, node)
  local prev = node

  if (tree.children == nil) then
    tree.children = {}
  end

  if i < 0 then
    i = #tree.children - i
  end

  for k = i, #tree.children do
    local n = tree.children[k]
    tree.children[k] = prev
    prev = n
  end

  tree.children[#tree.children + 1] = prev
end

-- Find the parent index of a node in its parent’s children.
local function find_parent_index(tree, node)
  for i, child in ipairs(tree.children) do
    if (child == node) then
      return i
    end
  end
end

-- Add a node as child of another node.
local function push_tree(tree, i, name, dir)
  local parent, n = M.get_node_and_parent_by_nb(tree, i)

  if (n == nil) then
    notify('push_tree nope', vim.log.levels.ERROR)
    return
  end

  local node = M.Node(name, nil)

  if (dir == M.MoveDir.INSIDE_START) then
    insert_node(n, 1, node)
  elseif (dir == M.MoveDir.INSIDE_END) then
    insert_node(n, -1, node)
  elseif (parent ~= nil) then
    local index = find_parent_index(parent, n)

    if (dir == M.MoveDir.ABOVE) then
      insert_node(parent, index, node)
    elseif (dir == M.MoveDir.BELOW) then
      insert_node(parent, index + 1, node)
    end
  else
    notify('forbidden node creation', vim.log.levels.WARN)
  end

  M.rerender(tree)
end

-- Ask the user for input and the node in the tree at the given direction.
M.push_tree_cursor = function(tree, dir)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.ui.input({ prompt = 'Node name: ' }, function(input)
    if (input ~= nil) then
      push_tree(tree, line, input, dir)
    end
  end)
end

-- Remove a node at index i in the given tree.
local function remove_node(tree, i)
  for k = i, #tree.children do
    tree.children[k] = tree.children[k + 1]
  end

  if (#tree.children == 0) then
    tree.children = nil
  end
end

-- Delete a node at a given location.
local function delete_node(tree, i)
  local parent, node = M.get_node_and_parent_by_nb(tree, i)

  if (node == nil) then
    notify('delete_node nope', 4)
    return
  end

  if (parent == nil) then
    return false
  end

  local children = {}
  for _, child in ipairs(parent.children) do
    if (child ~= node) then
      children[#children + 1] = child
    end
  end

  if (#children == 0) then
    children = nil
  end

  parent.children = children

  M.rerender(tree)
end

-- Delete the node under the cursor.
M.delete_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  delete_node(tree, line)
end

-- Rename a node at a given location.
local function rename_node(tree, i)
  local node = M.get_node_by_nb(tree, i)

  if (node == nil) then
    notify('rename_node nope', 4)
    return
  end

  vim.ui.input({ prompt = 'Rename node: ', default = node.contents[1].text }, function(input)
    if (input ~= nil) then
      node.contents[1].text = input
    end
  end)

  M.rerender(tree)
end

-- Rename the node under the cursor.
M.rename_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  rename_node(tree, line)
end

-- Change a node’s icon at a given location.
local function change_icon_node(tree, i)
  local node = M.get_node_by_nb(tree, i)

  if (node == nil) then
    notify('change_icon_node nope', 4)
    return
  end

  local prompt = 'Node icon: '
  if (node.icon ~= nil) then
    prompt = prompt .. node.icon .. ' -> '
  end

  vim.ui.input({ prompt = prompt }, function(input)
    if (input ~= nil) then
      node.icon = input
    end
  end)

  M.rerender(tree)
end

-- Change the icon of the node under the cursor.
M.change_icon_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  change_icon_node(tree, line)
end

local function compute_node_name_and_hl(node)
  local name = ''
  local partial_hls = {}

  local node_group = compute_hl(node)
  -- the icon goes first
  if (node.icon ~= nil) then
    name = node.icon
    partial_hls[#partial_hls + 1] = {
      group = node_group,
      width = #name,
    }
  end

  -- then the contents
  for _, content in ipairs(node.contents) do
    name = name .. content.text

    partial_hls[#partial_hls + 1] = {
      group = node_group,
      width = #content.text
    }
  end

  -- special case for the first highlight:
  if (node.type == nil) then
    if (node.children ~= nil) then
      partial_hls[#partial_hls - #node.contents + 1].group = M.opts.hl_node_parent
    elseif (node.data == nil) then
      partial_hls[#partial_hls - #node.contents + 1].group = M.opts.hl_modifier_empty
    end
  end

  -- special marker for local roots
  if (node.type == M.TreeType.LOCAL_ROOT) then
    local marker = ' ' .. M.opts.local_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = M.opts.hl_modifier_local,
      width = #marker,
    }
  end

  -- special marker for data
  if (node.data ~= nil) then
    local marker = ' ' .. M.opts.data_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = M.opts.hl_modifier_grey,
      width = #marker,
    }
  end

  -- special marker for selection
  if (node.is_selected) then
    local marker = ' ' .. M.opts.selected_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = M.opts.hl_modifier_selected,
      width = #marker,
    }
  end

  return name, partial_hls
end

local function render_node(node, depth, lines, hls)
  local line = string.rep(' ', depth * 2)
  local name, partial_hls = compute_node_name_and_hl(node)
  local hl_col_start = #line
  local hl_line = #lines

  if (node.children ~= nil) then
    if (node.is_expanded) then
      local mark = ' '
      local hl_col_end = hl_col_start + #mark
      hls[#hls + 1] = { group = M.opts.hl_mark_open, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
      lines[#lines + 1] = line .. mark .. name

      for _, hl in ipairs(partial_hls) do
        hl_col_start = hl_col_end
        hl_col_end = hl_col_start + hl.width
        hls[#hls + 1] = { group = hl.group, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
      end

      depth = depth + 1
      for _, child in ipairs(node.children) do
        render_node(child, depth, lines, hls)
      end
    else
      local mark = ' '
      local hl_col_end = hl_col_start + #mark
      hls[#hls + 1] = { group = M.opts.hl_mark_closed, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
      lines[#lines + 1] = line .. mark .. name

      for _, hl in ipairs(partial_hls) do
        hl_col_start = hl_col_end
        hl_col_end = hl_col_start + hl.width
        hls[#hls + 1] = { group = hl.group, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
      end
    end
  else
    local hl_col_end = hl_col_start
    lines[#lines + 1] = line .. name

    for _, hl in ipairs(partial_hls) do
      hl_col_start = hl_col_end
      hl_col_end = hl_col_start + hl.width
      hls[#hls + 1] = { group = hl.group, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
    end
  end
end

local function render_tree(tree)
  local lines = {}
  local hls = {}
  render_node(tree, 0, lines, hls)
  return lines, hls
end

M.render = function(tree, bufnr)
  local lines, hls = render_tree(tree)

  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)

  -- set the lines
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  -- apply the highlights
  for _, hl in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(bufnr, 0, hl.group, hl.line, hl.col_start, hl.col_end)
  end

  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

-- Re-render a tree if it was already rendered buffer.
M.rerender = function(tree)
  M.render(tree, 0)
end

-- Insert keymaps into the given buffer.
local function insert_keymaps(bufnr, tree, data_dir)
  local keyset = {}

  for key, _ in pairs(M.keymaps.normal) do
    keyset[key] = true
  end

  for key, _ in pairs(M.keymaps.selection) do
    keyset[key] = true
  end

  for key, _ in pairs(keyset) do
    vim.keymap.set('n', key, function()
      local keymap = get_keymap()

      if (keymap == nil) then
        notify('no active keymap', vim.log.levels.WARN)
        return
      end

      local cmd = keymap[key]

      if (cmd == nil) then
        notify('no command bound to ' .. tostring(key), vim.log.levels.WARN)
        return
      end

      cmd(tree, data_dir)
    end, { buffer = bufnr, noremap = true, silent = true })
  end
end

M.open_tree = function(tree, data_dir)
  -- window
  vim.api.nvim_cmd({ cmd = 'vsplit'}, {})
  vim.api.nvim_win_set_width(0, M.opts.width)

  -- buffer
  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(bufnr, 'mind')
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'mind')
  vim.api.nvim_win_set_option(0, 'nu', false)

  -- tree
  M.render(tree, bufnr)

  -- keymaps
  insert_keymaps(bufnr, tree, data_dir)
end

local function get_project_data_dir()
  local local_mind = path:new('.mind/data')
  if (local_mind:is_dir()) then
    return tostring(local_mind)
  end

  return M.opts.data_dir
end

M.open_main = function()
  M.wrap_main_tree_fn(function(tree) M.open_tree(tree, M.opts.data_dir) end)
end

M.open_project = function(use_global)
  M.wrap_project_tree_fn(function(tree) M.open_tree(tree, get_project_data_dir()) end, false, nil, use_global)
end

M.close = function(tree)
  M.unselect_node(tree)
  vim.api.nvim_buf_delete(0, { force = true })
end

M.toggle_node = function(tree, i)
  local node = M.get_node_by_nb(tree, i)

  if (node ~= nil) then
    node.is_expanded = not node.is_expanded
    M.rerender(tree)
  end
end

-- Select a node.
--
-- A selected node can be operated on by different kind of operations.
local function select_node(tree, i)
  local parent, node = M.get_node_and_parent_by_nb(tree, i)

  if (node ~= nil) then
    node.is_selected = true
    tree.selected = { parent = parent, node = node }

    set_keymap(M.KeymapSelector.SELECTION)

    M.rerender(tree)
  end
end

-- Select the node under the cursor.
M.select_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  select_node(tree, line)
end

M.unselect_node = function(tree)
  if (tree.selected ~= nil) then
    tree.selected.node.is_selected = nil
    tree.selected = nil

    set_keymap(M.KeymapSelector.NORMAL)

    M.rerender(tree)
  end
end

M.toggle_select_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1

  if (tree.selected ~= nil) then
    local node = M.get_node_by_nb(tree, line)
    if (node == tree.selected.node) then
      M.unselect_node(tree)
    else
      M.unselect_node(tree)
      select_node(tree, line)
    end
  else
    select_node(tree, line)
  end
end

M.toggle_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  M.toggle_node(tree, line)
end

-- Move a source node at a target node in the same tree.
local function move_source_target_same_tree(tree, src, tgt)
  -- do nothing if src == tgt
  if (src == tgt) then
    return
  end

  if (tgt < src) then
    -- if we want to move src to tgt with target before source
    local prev = tree.children[src]

    for i = tgt, src do
      local node = tree.children[i]
      tree.children[i] = prev
      prev = node
    end
  else -- FIXME: THIS IS FUCKED
    -- if we want to move src to tgt with target after source
    local source = tree.children[src]
    for i = src, tgt - 1 do
      tree.children[i] = tree.children[i + 1]
    end

    tree.children[tgt - 1] = source
  end
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
