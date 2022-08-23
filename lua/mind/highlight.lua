-- Highlighting module.

local M = {}

M.create_highlight_groups = function(opts)
  -- highlight used on closed marks
  vim.api.nvim_set_hl(0, 'MindClosedMarker', { default = true, link = opts.ui.highlight.closed_marker })

  -- highlight used on open marks
  vim.api.nvim_set_hl(0, 'MindOpenMarker', { default = true, link = opts.ui.highlight.open_marker })

  -- highlight used on the name of the root node
  vim.api.nvim_set_hl(0, 'MindNodeRoot', { default = true, link = opts.ui.highlight.node_root })

  -- highlight used on regular nodes with no children
  vim.api.nvim_set_hl(0, 'MindNodeLeaf', { default = true, link = opts.ui.highlight.node_leaf })

  -- highlight used on regular nodes with children
  vim.api.nvim_set_hl(0, 'MindNodeParent', { default = true, link = opts.ui.highlight.node_parent })

  -- highlight used on the local marker
  vim.api.nvim_set_hl(0, 'MindLocalMarker', { default = true, link = opts.ui.highlight.local_marker })

  -- highlight used on the data marker
  vim.api.nvim_set_hl(0, 'MindDataMarker', { default = true, link = opts.ui.highlight.data_marker })

  -- highlight used on the URL marker
  vim.api.nvim_set_hl(0, 'MindURLMarker', { default = true, link = opts.ui.highlight.url_marker })

  -- highlight used on empty nodes (i.e. no children and no data)
  vim.api.nvim_set_hl(0, 'MindModifierEmpty', { default = true, link = opts.ui.highlight.modifier_empty })

  -- highlight used on the selection marker
  vim.api.nvim_set_hl(0, 'MindSelectMarker', { default = true, link = opts.ui.highlight.select_marker })
end

return M
