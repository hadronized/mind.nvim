# mind.lua, a (very) small plugin for note taking workflows

This plugin provides a very simple plugin for note taking:

- Create new notes by giving them a name.
- Browse and jump to the notes by fuzzy searching them.

## Dependencies

This plugin requires the following Lua plugins to be installed:

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Install

With [packer](https://github.com/wbthomason/packer.nvim):

```lua
use 'phaazon/mind.nvim'
```

## Getting started

Setup by calling the `setup` function in any of your `.lua` files:

```lua
use {
  'phaazon/mind.nvim',
  config = function()
    require'mind'.setup()
  end
}
```

## Lua API

The current API contains two functions:

- `mind.open_node()`: open a note by fuzzy searching it.
- `mind.create_node()`: prompt the user to enter a new node name and start editing it.

## Customizing the notes directory

By default, this plugin uses the `~/mind` directory. You can change this setting by passing the directory to the `setup`
function via the `node_dir` key:

```lua
require'mind'.setup {
  node_dir = '~/notes'
}
```
