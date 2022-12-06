-- Indexing capabilities.
--
-- This module contains the code used to index a tree by path, allowing to search and locate nodes quickly.

local M = {}

-- The index is a simple map between paths and nodes.
M.index = {}

-- Index a node and its children
M.index_node = function(parent_path, parent, node, filter, opts)
  local path = string.format('%s%s', parent_path, node.type and '/' or node.contents[1].text)

  if filter == nil or filter(node) then
    M.index[#M.index + 1] = { path = path, parent = parent, node = node }
  end

  if node.children ~= nil then
    local child_path = node.type and path or path .. '/'
    for _, child in ipairs(node.children) do
      M.index_node(child_path, node, child, filter, opts)
    end
  end
end

-- Index a whole tree.
M.index_tree = function(tree, filter, opts)
  M.index = {}
  M.index_node('', nil, tree, filter, opts)
end

-- Search through the index.
M.search_index = function(tree, prompt, filter, f, opts)
  local format_item = function(item)
    local prefix = ''

    if item.node.data ~= nil then
      prefix = opts.ui.data_marker
    elseif item.node.url ~= nil then
      prefix = opts.ui.url_marker
    end

    return prefix .. item.path
  end

  M.index_tree(tree, filter, opts)

  vim.ui.select(M.index, { prompt = prompt, format_item = format_item }, function(item)
    if item ~= nil then
      f(item)
    end
  end)
end

return M
