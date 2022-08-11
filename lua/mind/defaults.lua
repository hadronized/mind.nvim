-- Default configuration options.

return {
  -- persistence, both for the tree state and data files
  persistence = {
    -- path where the global mind tree is stored
    state_path = '~/.local/share/mind.nvim/mind.json',

    -- directory where to create global data files
    data_dir = '~/.local/share/mind.nvim/data',
  },

  -- edit options
  edit = {
    -- file extension to use when creating a data file
    data_extension = '.md',

    -- default header to put in newly created data file
    data_header = '# %s',
  },

  -- UI options
  ui = {
    -- default width of the tree view window
    width = 30,

    -- marker used to identify the root of the tree (left to its name)
    root_marker = ' ',

    -- marker used to identify a local root (right to its name)
    local_marker = 'local',

    -- marker used to show that a node has an associated data file
    data_marker = '',

    -- marker used to show that a node is currently selected
    select_marker = '',

    -- highlight options
    highlight = {
      -- highlight used on closed marks
      closed_marker = 'LineNr',

      -- highlight used on open marks
      open_marker = 'LineNr',

      -- highlight used on the name of the root node
      node_root = 'Function',

      -- highlight used on regular nodes with no children
      node_leaf = 'String',

      -- highlight used on regular nodes with children
      node_parent = 'Title',

      -- highlight used on the local marker
      local_marker = 'Comment',

      -- highlight used on the data marker
      data_marker = 'Grey',

      -- highlight used on empty nodes (i.e. no children and no data)
      modifier_empty = 'CursorLineNr',

      -- highlight used on the selection marker
      select_marker = 'Error',
    },
  },

  -- default keymaps; see 'mind.commands' for a list of commands that can be mapped to keys here
  keymaps = {
    -- keybindings when navigating the tree normally
    normal = {
      ['<cr>'] = 'open_data',
      ['<tab>'] = 'toggle_node',
      ['/'] = 'node_at_path',
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

    -- keybindings when a node is selected
    selection = {
      I = 'move_inside_start',
      i = 'move_inside_end',
      O = 'move_above',
      o = 'move_below',
      q = 'quit',
      x = 'select',
    },

    -- keybindings when a path is selected
    by_path = {
      d = 'delete',
      r = 'rename',
      q = 'quit',
    }
  }
}
