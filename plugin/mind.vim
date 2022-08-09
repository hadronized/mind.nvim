if !has('nvim-0.8.0')
  echohl Error
  echom 'This plugin only works with Neovim >= v0.8.0'
  echohl clear
  finish
endif

command! MindOpenMain lua require'mind'.open_main()
command! MindOpenProject lua require'mind'.open_project()
command! MindReloadState lua require'mind'.load_state()
