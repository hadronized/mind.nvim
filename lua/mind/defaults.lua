-- Default configuration options.

-- URL opener depends on the platform.
local sysname = vim.loop.os_uname().sysname
local url_open
if sysname == 'Linux' then
  url_open = 'xdg-open'
elseif sysname == 'Darwin' then
  url_open = 'open'
elseif sysname == 'Windows' then
  url_open = 'start ""'
end

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

    -- default header to put in newly created data files
    data_header = '# %s',

    -- format string for copied links
    copy_link_format = '[](%s)'
  },

  -- tree options
  tree = {
    -- automatically create nodes (when looking for paths for example)
    automatic_creation = true,

    -- automatically create data file when trying to open one that doesn’t
    -- have any data yet
    automatic_data_creation = false,
  },

  -- UI options
  ui = {
    -- commands used to open URLs
    url_open = url_open,

    -- default width of the tree view window
    width = 30,

    -- default opening direction of the tree view window
    open_direction = 'left',

    -- marker used for empty indentation
    empty_indent_marker = '│',

    -- marker used for node indentation
    node_indent_marker = '└',

    -- marker used to identify the root of the tree (left to its name)
    root_marker = ' ',

    -- marker used to identify a local root (right to its name)
    local_marker = 'local',

    -- marker used to show that a node has an associated data file
    data_marker = ' ',

    -- marker used to show that a node has an URL
    url_marker = ' ',

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
      data_marker = 'Comment',

      -- highlight used on the url marker
      url_marker = 'Comment',

      -- highlight used on empty nodes (i.e. no children and no data)
      modifier_empty = 'Comment',

      -- highlight used on the selection marker
      select_marker = 'Error',
    },

    -- preset of icons
    icon_preset = {
      { ' ', 'Sub-project' },
      { ' ', 'Journal, newspaper, weekly and daily news' },
      { ' ', 'For when you have an idea' },
      { ' ', 'Note taking?' },
      { '陼', 'Task management' },
      { ' ', 'Uncheck, empty square or backlog' },
      { ' ', 'Full square or on-going' },
      { ' ', 'Check or done' },
      { ' ', 'Trash bin, deleted, cancelled, etc.' },
      { ' ', 'GitHub' },
      { ' ', 'Monitoring' },
      { ' ', 'Internet, Earth, everyone!' },
      { ' ', 'Frozen, on-hold' },
    }
  },

  -- default keymaps; see 'mind.commands' for a list of commands that can be mapped to keys here
  keymaps = {
    -- keybindings when navigating the tree normally
    normal = {
      ['<cr>'] = 'open_data',
      ['<s-cr>'] = 'open_data_index',
      ['<tab>'] = 'toggle_node',
      ['<s-tab>'] = 'toggle_parent',
      ['/'] = 'select_path',
      ['$'] = 'change_icon_menu',
      c = 'add_inside_end_index',
      I = 'add_inside_start',
      i = 'add_inside_end',
      l = 'copy_node_link',
      L = 'copy_node_link_index',
      d = 'delete',
      D = 'delete_file',
      O = 'add_above',
      o = 'add_below',
      q = 'quit',
      r = 'rename',
      R = 'change_icon',
      u = 'make_url',
      x = 'select',
    },

    -- keybindings when a node is selected
    selection = {
      ['<cr>'] = 'open_data',
      ['<tab>'] = 'toggle_node',
      ['<s-tab>'] = 'toggle_parent',
      ['/'] = 'select_path',
      I = 'move_inside_start',
      i = 'move_inside_end',
      O = 'move_above',
      o = 'move_below',
      q = 'quit',
      x = 'select',
    },
  }
}
