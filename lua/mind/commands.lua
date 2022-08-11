-- User-facing available commands.

-- FIXME
return {
  toggle_node = function(tree)
    M.toggle_node_cursor(tree)
    M.save_state()
  end,

  quit = function(tree)
    M.reset(tree)
    M.close(tree)
  end,

  add_above = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.ABOVE)
    M.save_state()
  end,

  add_below = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.BELOW)
    M.save_state()
  end,

  add_inside_start = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.INSIDE_START)
    M.save_state()
  end,

  add_inside_end = function(tree)
    M.push_tree_cursor(tree, M.MoveDir.INSIDE_END)
    M.save_state()
  end,

  delete = function(tree)
    M.delete_node_cursor(tree)
    M.save_state()
  end,

  rename = function(tree)
    M.conditionally_run_by_path(
      function() M.rename_node_cursor(tree) end,
      function(node) M.rename_node(tree, node) end
    )

    M.reset(tree)
    M.save_state()
  end,

  open_data = function(tree, data_dir)
    M.open_data_cursor(tree, data_dir)
    M.save_state()
  end,

  change_icon = function(tree)
    M.change_icon_node_cursor(tree)
    M.save_state()
  end,

  select = function(tree)
    M.toggle_select_node_cursor(tree)
  end,

  move_above = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.ABOVE)
    M.save_state()
  end,

  move_below = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.BELOW)
    M.save_state()
  end,

  move_inside_start = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.INSIDE_START)
    M.save_state()
  end,

  move_inside_end = function(tree)
    M.selected_move_cursor(tree, M.MoveDir.INSIDE_END)
    M.save_state()
  end,

  node_at_path = function(tree)
    vim.ui.input({ prompt = 'Path: ', default = '/' }, function(input)
      if (input ~= nil) then
        M.enable_by_path(input, M.get_node_by_path(tree, input))
      end
    end)
  end,
}
