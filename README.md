# mind.lua, a (very) small plugin for notetaking and task workflows

<!-- vim-markdown-toc GFM -->

* [Features](#features)
* [Dependencies](#dependencies)
* [Getting started](#getting-started)
  * [Install](#install)
  * [Customizing the notes directory](#customizing-the-notes-directory)
  * [Keybindings](#keybindings)
* [Lua API](#lua-api)

<!-- vim-markdown-toc -->

# Features

This plugin provides a very simple plugin for note taking and task management:

- Notes:
  - Create new notes by giving them a name.
  - Browse and jump to the notes by fuzzy searching them.
- Journal:
  - Access the daily journal easily.
  - Browse and jump to the previous journal entries by fuzzy searching them.
- Task managemente:
  - Create new TODO, WIP or DONE tasks.
  - Browse and jump categories of tasks (TODO, WIP and DONE).
  - Move task between TODO, WIP an DONE category.

# Dependencies

This plugin requires the following Lua plugins to be installed:

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

# Getting started

## Install

With [packer](https://github.com/wbthomason/packer.nvim):

```lua
use 'phaazon/mind.nvim'
```

Setup by calling the `setup` function in any of your `.lua` files:

```lua
use {
  'phaazon/mind.nvim',
  config = function()
    require'mind'.setup()
  end
}
```

## Customizing the notes directory

By default, this plugin uses the `~/mind` directory. You can change this setting by passing the directory to the `setup`
function via the `dir` key:

```lua
require'mind'.setup {
  dir = {
    notes = "~/mind/notes",
    journal = "~/mind/journal",
    todo = "~/mind/tasks/todo",
    wip = "~/mind/tasks/wip",
    done = "~/mind/tasks/done",
  }
}
```

## Keybindings

This plugin comes with no keybindings by default; you must create them on your side. Example of a possible
configuration:

```lua
local function remap(mode, lhs, rhs)
  vim.api.nvim_set_keymap(mode, lhs, rhs, { silent = true, noremap = true })
end

remap('n', '<leader>nn', "<cmd>lua require'mind'.open_note()<cr>")
remap('n', '<leader>nN', "<cmd>lua require'mind'.new_note()<cr>")
remap('n', '<leader>nt', "<cmd>lua require'mind'.open_todo()<cr>")
remap('n', '<leader>nT', "<cmd>lua require'mind'.new_todo()<cr>")
remap('n', '<leader>ns', "<cmd>lua require'mind'.open_wip()<cr>")
remap('n', '<leader>nS', "<cmd>lua require'mind'.new_wip()<cr>")
remap('n', '<leader>nd', "<cmd>lua require'mind'.open_done()<cr>")
remap('n', '<leader>nD', "<cmd>lua require'mind'.new_done()<cr>")
remap('n', '<leader>nj', "<cmd>lua require'mind'.open_daily()<cr>")
remap('n', '<leader>nJ', "<cmd>lua require'mind'.open_journal()<cr>")
remap('n', '<leader>n$t', "<cmd>lua require'mind'.mark_todo()<cr>")
remap('n', '<leader>n$s', "<cmd>lua require'mind'.mark_wip()<cr>")
remap('n', '<leader>n$d', "<cmd>lua require'mind'.mark_done()<cr>")
```

# Lua API

The current API contains two functions:

- `mind.open_note()`: open a note by fuzzy searching it.
- `mind.new_note()`: prompt the user to enter a new node name and start editing it.
- `mind.open_journal()`: open a journal entry by fuzzy searching it.
- `mind.open_daily()`: automatically jump to the daily journal entry.
- `mind.open_todo()`: open a TODO by fuzzy searching it.
- `mind.new_todo()`: create a new TODO entry.
- `mind.open_wip()`: open a WIP by fuzzy searching it.
- `mind.new_wip()`: create a new WIP entry.
- `mind.open_done()`: open a DONE by fuzzy searching it.
- `mind.new_done()`: create a new DONE entry.
