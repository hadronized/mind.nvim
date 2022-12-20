-- Everything relating to the UI.
local M = {}

local mind_node = require'mind.node'

-- A per-tree render cache.
--
-- Once a tree is rendered in a buffer, it is added to that cache, so that operations that require an update of the tree
-- can update the buffer, even if the cursor is in another buffer / window.
--
-- Opening a buffer will always replace that value. We also store the tree to ensure that updating another tree is
-- authorized while a different tree is displayed (damn that’s powerful right?!).
M.render_cache = {}

-- Get the highlight group to use for a node given its status.
local function node_hl(node)
  if (node.type == mind_node.TreeType.ROOT) then
    return 'MindNodeRoot'
  elseif (node.type == mind_node.TreeType.LOCAL_ROOT) then
    return 'MindNodeRoot'
  elseif (node.children ~= nil) then
    return 'MindNodeParent'
  else
    return 'MindNodeLeaf'
  end
end

-- Compute the text line to display for a given node
local function node_to_line(node, opts)
  local name = ''
  local partial_hls = {}

  local node_group = node_hl(node)
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
      partial_hls[#partial_hls - #node.contents + 1].group = 'MindNodeParent'
    elseif (node.data == nil and node.url == nil) then
      partial_hls[#partial_hls - #node.contents + 1].group = 'MindModifierEmpty'
    end
  end

  -- special marker for local roots
  if (node.type == mind_node.TreeType.LOCAL_ROOT) then
    local marker = ' ' .. opts.ui.local_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = 'MindLocalMarker',
      width = #marker,
    }
  end

  -- special marker for data / URL nodes
  if node.data ~= nil then
    local marker = ' ' .. opts.ui.data_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = 'MindDataMarker',
      width = #marker,
    }
  elseif node.url ~= nil then
    local marker = ' ' .. opts.ui.url_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = 'MindURLMarker',
      width = #marker,
    }
  end

  -- special marker for selection
  if (node.is_selected) then
    local marker = ' ' .. opts.ui.select_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = 'MindSelectMarker',
      width = #marker,
    }
  end

  return name, partial_hls
end

-- Render a node into a set of lines.
--
-- That function will turn the node into a text line as well as its children, respecting the depth level.
local function render_node(node, indent, is_last, lines, hls, opts)
  local line

  if is_last then
    if node.type ~= nil then
      line = indent
      indent = indent
    else
      line = indent .. opts.ui.node_indent_marker .. ' '
      indent = indent .. '  '
    end
  else
    line = indent .. opts.ui.empty_indent_marker .. ' '
    indent = indent .. opts.ui.empty_indent_marker .. ' '
  end

  local name, partial_hls = node_to_line(node, opts)
  local hl_col_start = #line
  local hl_line = #lines

  hls[#hls + 1] = {
    group = 'MindOpenMarker',
    line = hl_line,
    col_start = 0,
    col_end = #line,
  }

  if (node.children ~= nil) then
    if (node.is_expanded) then
      local mark = ' '
      local hl_col_end = hl_col_start + #mark

      hls[#hls + 1] = {
        group = 'MindOpenMarker',
        line = hl_line,
        col_start = hl_col_start,
        col_end = hl_col_end
      }

      lines[#lines + 1] = line .. mark .. name

      for _, hl in ipairs(partial_hls) do
        hl_col_start = hl_col_end
        hl_col_end = hl_col_start + hl.width

        hls[#hls + 1] = {
          group = hl.group,
          line = hl_line,
          col_start = hl_col_start,
          col_end = hl_col_end
        }
      end

      for i = 1, #node.children - 1 do
        local child = node.children[i]
        render_node(child, indent, false, lines, hls, opts)
      end
      render_node(node.children[#node.children], indent, true, lines, hls, opts)
    else
      local mark = ' '
      local hl_col_end = hl_col_start + #mark

      hls[#hls + 1] = {
        group = 'MindClosedMarker',
        line = hl_line,
        col_start = hl_col_start,
        col_end = hl_col_end
      }

      lines[#lines + 1] = line .. mark .. name

      for _, hl in ipairs(partial_hls) do
        hl_col_start = hl_col_end
        hl_col_end = hl_col_start + hl.width
        hls[#hls + 1] = {
          group = hl.group,
          line = hl_line,
          col_start = hl_col_start,
          col_end = hl_col_end
        }
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

-- Render a whole tree as a list of lines, returing all the lines to display as well as the highlights to apply.
local function render_tree(tree, opts)
  local lines = {}
  local hls = {}
  render_node(tree, '', true, lines, hls, opts)
  return lines, hls
end

-- Open a new window and return a handle to its buffer.
M.open_window = function(opts)
  local bufnr
  if M.render_cache.bufnr ~= nil then
    -- reuse if it’s currently displayed / not destroyed
    bufnr = M.render_cache.bufnr
  else
    bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'mind')
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')

    -- window
    vim.api.nvim_exec("vsp", false)
    if opts.ui.open_direction == 'left' then
        vim.api.nvim_exec("wincmd H", false)
    end
    vim.api.nvim_win_set_width(0, opts.ui.width)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.api.nvim_win_set_option(0, 'nu', false)
    vim.api.nvim_win_set_option(0, 'rnu', false)
  end

  return bufnr
end

-- Render a tree into a buffer.
M.render = function(tree, bufnr, opts)
  local lines, hls = render_tree(tree, opts)

  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)

  -- set the lines for the whole buffer, replacing everything
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  -- apply all the highlights at once
  for _, hl in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(bufnr, 0, hl.group, hl.line, hl.col_start, hl.col_end)
  end

  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)

  M.render_cache = { tree_uid = tree.uid, bufnr = bufnr }
end

-- Re-render a tree.
--
-- That function is almost similar to M.render, but it doesn’t expect a bufnr. Instead, it takes a tree that must be
-- re-rendered, and if that tree is the same as the one in M.render_cache, then a render is performed again.
--
-- If the tree is different, no render is performed.
M.rerender = function(tree, opts)
  if M.render_cache.tree_uid ~= nil and tree.uid == M.render_cache.tree_uid then
    M.render(tree, M.render_cache.bufnr, opts)
  end
end

-- Run a command by passing it the cursor line.
M.with_cursor = function(f)
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  f(line)
end

-- Ask the user for input with a given prompt and run the tree function on it.
M.with_input = function(prompt, default, f)
  vim.ui.input({ prompt = prompt, default = default }, function(input)
    if (input ~= nil) then
      f(input)
    end
  end)
end

-- Run a command by asking for confirmation before. If the answer is 'y', run the command, otherwise abort.
M.with_confirmation = function(prompt, f)
  vim.ui.input({ prompt = prompt .. ' (y/N) ' }, function(input)
    if (input ~= nil and input == 'y') then
      f()
    end
  end)
end

return M
