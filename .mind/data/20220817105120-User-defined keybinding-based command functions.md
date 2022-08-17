# User-defined keybinding-based command functions

Users should be able to define command functions in the keymaps. Everything is already implemented for them to do that
but one piece: when we precompute keymaps, we need to check whether the value of a key is a string or not. If it’s not a
string, we don’t touch it, so that users can set them to command functions directly.
