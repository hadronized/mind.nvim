-- Everything relating to the UI.
local M = {}

local mind_node = require'mind.node'

-- Get the highlight group to use for a node given its status.
local function node_hl(node, opts)
  if (node.type == mind_node.TreeType.ROOT) then
    return opts.ui.highlight.node_root
  elseif (node.type == mind_node.TreeType.LOCAL_ROOT) then
    return opts.ui.highlight.node_root
  elseif (node.children ~= nil) then
    return opts.ui.highlight.node_parent
  else
    return opts.ui.highlight.node_leaf
  end
end

-- Compute the text line to display for a given node
local function node_to_line(node, opts)
  local name = ''
  local partial_hls = {}

  local node_group = node_hl(node, opts)
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
      partial_hls[#partial_hls - #node.contents + 1].group = opts.ui.highlight.node_parent
    elseif (node.data == nil) then
      partial_hls[#partial_hls - #node.contents + 1].group = opts.ui.highlight.modifier_empty
    end
  end

  -- special marker for local roots
  if (node.type == mind_node.TreeType.LOCAL_ROOT) then
    local marker = ' ' .. opts.ui.local_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = opts.ui.highlight.local_marker,
      width = #marker,
    }
  end

  -- special marker for data / URL nodes
  if node.data ~= nil then
    local marker = ' ' .. opts.ui.data_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = opts.ui.highlight.data_marker,
      width = #marker,
    }
  elseif node.url ~= nil then
    local marker = ' ' .. opts.ui.url_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = opts.ui.highlight.url_marker,
      width = #marker,
    }
  end

  -- special marker for selection
  if (node.is_selected) then
    local marker = ' ' .. opts.ui.select_marker
    name = name .. marker

    partial_hls[#partial_hls + 1] = {
      group = opts.ui.highlight.select_marker,
      width = #marker,
    }
  end

  return name, partial_hls
end

-- Render a node into a set of lines.
--
-- That function will turn the node into a text line as well as its children, respecting the depth level.
local function render_node(node, depth, lines, hls, opts)
  local line = string.rep(' ', depth * 2)
  local name, partial_hls = node_to_line(node, opts)
  local hl_col_start = #line
  local hl_line = #lines

  if (node.children ~= nil) then
    if (node.is_expanded) then
      local mark = ' '
      local hl_col_end = hl_col_start + #mark
      hls[#hls + 1] = { group = opts.ui.highlight.open_marker, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
      lines[#lines + 1] = line .. mark .. name

      for _, hl in ipairs(partial_hls) do
        hl_col_start = hl_col_end
        hl_col_end = hl_col_start + hl.width
        hls[#hls + 1] = { group = hl.group, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
      end

      depth = depth + 1
      for _, child in ipairs(node.children) do
        render_node(child, depth, lines, hls, opts)
      end
    else
      local mark = ' '
      local hl_col_end = hl_col_start + #mark
      hls[#hls + 1] = { group = opts.ui.highlight.closed_marker, line = hl_line, col_start = hl_col_start, col_end = hl_col_end }
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

-- Render a whole tree as a list of lines, returing all the lines to display as well as the highlights to apply.
local function render_tree(tree, opts)
  local lines = {}
  local hls = {}
  render_node(tree, 0, lines, hls, opts)
  return lines, hls
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
