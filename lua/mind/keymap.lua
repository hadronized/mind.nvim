-- Keymap and keybindings.

local M = {}

-- Selector for keymap.
--
-- A keymap selector is a way to pick which keymap should be used. When a command allows for UI, it can set the
-- currently active keymap. The keymap contains user-defined keybindings that will then be resolved when the user
-- presses their defined keys.
M.KeymapSelector = {
  NORMAL = 'normal',
  SELECTION = 'selection',
  BY_PATH = 'by_path',
}

-- Keymaps.
--
-- A keymap is a map between a key and a command name.
--
-- If M.precompute_keymaps() is called, the mapping is not between a key and a command name anymore but between a key and a
-- Lua function directly, preventing the indirection.
M.keymaps = {
  -- Currently active keymap selector.
  selector = M.KeymapSelector.NORMAL,

  -- Normal mappings.
  normal = {},

  -- Selection mappings.
  selection = {},
}

-- Initialize keymaps.
M.init_keymaps = function(opts)
  M.keymaps.normal = opts.keymaps.normal
  M.keymaps.selection = opts.keymaps.selection
end

-- Set the currently active keymap.
M.set_keymap = function(selector)
  M.keymaps.selector = selector
end

-- Get the currently active keymap.
M.get_keymap = function()
  return M.keymaps[M.keymaps.selector]
end

return M
