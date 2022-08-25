-- Keymaps and keybindings.

local M = {}

local notify = require'mind.notify'.notify

-- Selector for keymap.
--
-- A keymap selector is a way to pick which keymap should be used. When a command allows for UI, it can set the
-- currently active keymap. The keymap contains user-defined keybindings that will then be resolved when the user
-- presses their defined keys.
M.KeymapSelector = {
  NORMAL = 'normal',
  SELECTION = 'selection',
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

-- Insert keymaps into the given buffer.
M.insert_keymaps = function(bufnr, get_tree, data_dir, save_tree, opts)
  local keyset = {}

  for key, _ in pairs(M.keymaps.normal) do
    keyset[key] = true
  end

  for key, _ in pairs(M.keymaps.selection) do
    keyset[key] = true
  end

  -- the input for the command function
  local args = {
    get_tree = get_tree,
    data_dir = data_dir,
    save_tree = save_tree,
    opts = opts
  }

  for key, _ in pairs(keyset) do
    vim.keymap.set('n', key, function()
      local keymap = M.get_keymap()

      if (keymap == nil) then
        notify('no active keymap', vim.log.levels.WARN)
        return
      end

      local cmd = keymap[key]

      if (cmd == nil) then
        notify('no command bound to ' .. tostring(key), vim.log.levels.WARN)
        return
      end

      cmd(args)
    end, { buffer = bufnr, noremap = true, silent = true })
  end
end

return M
