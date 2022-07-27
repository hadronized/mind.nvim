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

function get_ith(node, i)
  if (i == 0) then
    return node
  end

  i = i - 1

  if (node.children ~= nil and node.is_expanded) then
    for _, child in ipairs(node.children) do
      n, i = get_ith(child, i)

      if (n ~= nil) then
        return n
      end
    end
  end

  return nil, i
end

M.get_node_by_nb = function(tree, i)
  local node, _ = get_ith(tree, i)
  return node
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

M.render = function(bufnr, tree)
  local lines = M.to_lines(tree)

  tree.bufnr = bufnr

  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'mind')
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

M.toggle_node = function(tree, i)
  local node = M.get_node_by_nb(tree, i)

  if (node ~= nil) then
    node.is_expanded = not node.is_expanded
  end

  if (tree.bufnr ~= nil) then
    M.render(tree.bufnr, tree)
  end
end

M.toggle_node_cursor = function(tree)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  M.toggle_node(tree, line)
end

M.data = Node('Mind', {
  Node('Tasks'),
  Node('Journal', {
    Node('Foo'),
    Node('Bar'),
    Node('Zoo'),
  }),
  Node('Notes'),
})

return M
