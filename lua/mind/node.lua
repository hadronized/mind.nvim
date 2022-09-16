---Node and trees operations.
local M = {}

local notify = require'mind.notify'.notify

-- A tree is either a root or a local root.
M.TreeType = {
  ROOT = 0,
  LOCAL_ROOT = 1,
}

-- Move direction.
--
-- That enumeration is used when a node is going to be moved into another, whether the first node already exists or not.
-- There are currently several modes:
--
-- - Above: move the node above the current / selected node.
-- - Below: move the node belowe the current / selected node.
-- - Inside (start): move the node inside the current / selected node, at the beginning of the children list.
-- - Inside (end): move the node inside the current / selected node, at the end of the children list.
M.MoveDir = {
  ABOVE = 0,
  BELOW = 1,
  INSIDE_START = 2,
  INSIDE_END = 3,
}

---Create new node.
---@param name string name of the node
---@param children table|nil list of children. Pass `nil` if node shouldn't have children
---@return table
M.new_node = function(name, children)
  return {
    contents = {
      { text = name }
    },
    is_expanded = false,
    children = children
  }
end

---Get the `i`th node from the top by doing a DFS.
---
---`i` is rank of the node we want to get. If i is 0, then parent and node are returned as result. If not, this function will recurse into `node.children` (if any) and if `node.is_expanded` is `true`.
---@param parent table
---@param node table
---@param i number
---@return table|nil parent parent of the found node. `nil` if node doesn't exist or is root
---@return table|nil node the found node. `nil` if node doesn't exist
---@return number rank rank of the node we want to get. 0 means `parent` and `node` are returned
local function get_dfs(parent, node, i)
  if (i == 0) then
    return parent, node, i
  end

  i = i - 1

  if (node.children ~= nil and node.is_expanded) then
    for _, child in ipairs(node.children) do
      local p, n
      p, n, i = get_dfs(node, child, i)

      if (n ~= nil) then
        return p, n, i
      end
    end
  end

  return nil, nil, i
end

---Get a node in a tree by line.
---
---That function can be used directly with the line in the buffer the tree is displayed in. The only requirement is that
---the root of the tree has to start at line 1.
---@param tree table
---@param line number
---@return table|nil node
M.get_node_by_line = function(tree, line)
  local _, node, _ = get_dfs(nil, tree, line)
  return node
end

---Get a node and its parent in a tree by line.
---
---That function can be used directly with the line in the buffer the tree is displayed in. The only requirement is that
---the root of the tree has to start at line 1.
---@param tree table
---@param line number
---@return table|nil parent
---@return table|nil node
M.get_node_and_parent_by_line = function(tree, line)
  local parent, node, _ = get_dfs(nil, tree, line)
  return parent, node
end

---Get a node in a tree by path.
---
---The function stops when it arrives at the end of paths, that is, when i == #paths + 1.
---
---Despite signature, returns nothing if specified path does not exist and `create` is `false`.
---@param parent table|nil
---@param tree table
---@param paths string[] the list of paths to iterate through and `i` is the current path segment selector. For instance, paths[1] is the root and paths[2] is the name of the first child under the root.
---@param i number
---@param create boolean whether to create children if there is no node
---@return table|nil parent
---@return table tree
local function get_node_by_path_rec(parent, tree, paths, i, create)
  if (i == #paths + 1) then
    return parent, tree
  end

  local segment = paths[i]

  if (tree.children == nil) then
    if create then
      tree.children = { M.new_node(segment) }
    else
      -- no children, so this can’t be a solution
      return
    end
  end

  -- look for the child which name is the same as paths[i]
  for _, child in ipairs(tree.children) do
    if (child.contents[1].text == segment) then
      return get_node_by_path_rec(tree, child, paths, i + 1, create)
    end
  end

  if create then
    -- we haven’t found anything, so create the node nevertheless
    local node = M.new_node(segment)
    tree.children[#tree.children + 1] = node
    return get_node_by_path_rec(tree, node, paths, i + 1, create)
  end
end

---Get a node by path.
---
---Despite signature, returns nothing if specified path does not exist and `create` is `false`.
---@param tree table
---@param path string `"/"`-separated path that also starts with `"/"`. Each part of the past is the name of the node.
---Correct paths: `"/"`, `"/node"`, `"/foo/bar"`
---Incorrect paths: `""`, `"node"`, `"/node/"`
---@param create boolean whether to automatically create nodes that don't exist
---@return table|nil parent
---@return table node
M.get_node_by_path = function(tree, path, create)
  if (path == '/') then
    return nil, tree
  end

  local split_path = vim.split(path, '/')

  if (split_path[1] ~= '') then
    notify('path must start with a leading slash (/)', vim.log.levels.WARN)
    return
  end

  return get_node_by_path_rec(nil, tree, split_path, 2, create)
end

---Insert a node at index `i` in the given tree’s children.
---
---If `i` is negative, it starts after the end.
---@param tree table
---@param i number
---@param node table
M.insert_node = function(tree, i, node)
  local prev = node

  if tree.children == nil then
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

---Delete a node at index `i` in the given tree’s children.
---
---If `i` is negative, it starts after the end.
---@param tree table
---@param i number
M.delete_node = function(tree, i)
  if (tree.children == nil) then
    notify('cannot delete node; no children', vim.log.levels.ERROR)
    return
  end

  if i < 0 then
    i = #tree.children - i
  end

  for k = i, #tree.children do
    tree.children[k] = tree.children[k + 1]
  end

  if (#tree.children == 0) then
    tree.children = nil
  end
end

---Find the parent index of a node in its parent’s children.
---
---NOTE: nodes are compared with `==`, e.g. by reference and not by contents
---@param tree table
---@param node table
---@return number|nil
M.find_parent_index = function(tree, node)
  for i, child in ipairs(tree.children) do
    if (child == node) then
      return i
    end
  end
end

---Move a source node at a target node in the same tree.
---@param tree table
---@param src number index of the source node
---@param tgt number index of the target node
M.move_source_target_same_tree = function(tree, src, tgt)
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
  else
    -- if we want to move src to tgt with target after source
    local source = tree.children[src]
    for i = src, tgt - 1 do
      tree.children[i] = tree.children[i + 1]
    end

    tree.children[tgt - 1] = source
  end
end

return M
