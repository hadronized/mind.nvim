# Deal with window-picker

Currently, we use [nvim-window-picker](https://github.com/s1n7ax/nvim-window-picker) to select a window to open when we
run the `open_data` command on a node (whether it’s from the UI or a command function). This is requirement that is a
bit annoying, so we have two possibilities:

1. Create an “interface” plugin to pick windows. That plugin would be set with the implementation of users, so that we
   don’t have to explicitly depend on a given implementation.
2. Simply list the windows, and either take the last one if it’s not a Mind tree, or `rightb vsp`.
