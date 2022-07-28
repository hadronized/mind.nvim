local M = {}

function Node(name, children)
  return { name = name, is_expanded = false, children = children }
end

M.is_leaf = function(node)
  return node.children == nil or node.children == {}
end

M.is_functional = function(node)
  return type(node.compute) == 'function'
end

function get_ith(parent, node, i)
  if (i == 0) then
    return parent, node, nil
  end

  i = i - 1

  if (node.children ~= nil and node.is_expanded) then
    for _, child in ipairs(node.children) do
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

-- Add a node as children of another node.
function add_node(tree, i, name)
  local parent = M.get_node_by_nb(tree, i)

  if (parent == nil) then
    vim.notify('add_node nope')
    return
  end

  local node = Node(name)

  if (parent.children == nil) then
    parent.children = {}
  end

  parent.children[#parent.children + 1] = node

  M.rerender(tree)
end

-- Ask the user for input and add as a node at the current location.
M.input_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.ui.input({ prompt = 'Node name: ' }, function(input)
    if (input ~= nil) then
      add_node(tree, line, input)
    end
  end)
end

-- Delete a node at a given location.
function delete_node(tree, i)
  local parent, node = M.get_node_and_parent_by_nb(tree, i)

  if (node == nil) then
    vim.notify('add_node nope')
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
  return true
end

-- Delete the node under the cursor.
M.delete_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  delete_node(tree, line)
end

function render_node(node, depth, lines)
  local line = string.rep(' ', depth * 2)

  if (node.children ~= nil) then
    if (node.is_expanded) then
      lines[#lines + 1] = line .. ' ' .. node.name

      depth = depth + 1
      for _, child in ipairs(node.children) do
        render_node(child, depth, lines)
      end
    else
      lines[#lines + 1] = line .. ' ' .. node.name
    end
  else
    lines[#lines + 1] = line .. node.name
  end
end

M.to_lines = function(tree)
  local lines = {}
  render_node(tree, 0, lines)
  return lines
end

M.render = function(tree, bufnr)
  local lines = M.to_lines(tree)

  tree.bufnr = bufnr

  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

-- Re-render a tree if it was already rendered buffer.
M.rerender = function(tree)
  if (tree.bufnr) then
    M.render(tree, tree.bufnr)
  end
end

M.open = function(tree, default_keys)
  -- window
  vim.api.nvim_cmd({ cmd = 'vsplit'}, {})
  vim.api.nvim_win_set_width(0, 20)

  -- buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'mind')
  vim.api.nvim_win_set_option(0, 'nu', false)

  -- tree
  M.render(tree, bufnr)

  -- keymaps for debugging
  if (default_keys) then
    vim.keymap.set('n', '<cr>', function() M.toggle_node_cursor(tree) end, { buffer = true, noremap = true, silent = true })
    vim.keymap.set('n', '<tab>', function() M.toggle_node_cursor(tree) end, { buffer = true, noremap = true, silent = true })
    vim.keymap.set('n', 'q', M.close, { buffer = true, noremap = true, silent = true })
    vim.keymap.set('n', 'a', function() M.input_node_cursor(tree) end, { buffer = true, noremap = true, silent = true })
    vim.keymap.set('n', 'd', function() M.delete_node_cursor(tree) end, { buffer = true, noremap = true, silent = true })
  end
end

M.close = function()
  vim.api.nvim_win_hide(0)
end

M.toggle_node = function(tree, i)
  local node = M.get_node_by_nb(tree, i)

  if (node ~= nil) then
    node.is_expanded = not node.is_expanded
  end

  M.rerender(tree)
end

M.toggle_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  M.toggle_node(tree, line)
end

M.data = function()
  return Node('Mind', {
    Node('Tasks'),
    Node('Journal', {
      Node('Foo'),
      Node('Bar'),
      Node('Zoo'),
    }),
    Node('Notes'),
  })
end

return M
