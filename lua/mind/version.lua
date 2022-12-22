local M = {}

-- Current version trees are supported with.
--
-- Mind doesn’t support backward nor forward compatibility. When you are using Mind, this version number must be the
-- exact same in the trees you use. If it’s not, two situations:
--
-- - Your tree’s version number is less than Mind’s. In this case, a migration function will run on the tree to update
--   it to the current version.
-- - If it’s higher, it means that you need to upgrade Mind.
M.current_version = 1

M.Validation = {
  UP_TO_DATE = 0,
  NEED_MIGRATION = 1,
  NEED_UPDATE = 2
}

-- Check whether a tree is up to date.
M.check = function(tree)
  local version = tree.version

  if version == nil then
    return M.Validation.NEED_MIGRATION
  elseif version == M.current_version then
    return M.Validation.UP_TO_DATE
  elseif version > M.current_version then
    return M.Validation.NEED_MIGRATION
  end

  return M.Validation.NEED_MIGRATION
end

-- Migrate from version N to N+1 until N == M.current_version.
M.migrate = function(tree, save_tree)
  local mind_ui = require'mind.ui'
  local notify = require'mind.notify'.notify

  -- no version requires version 1
  if tree.version == nil then
    mind_ui.with_confirmation('Migrate from no version to version 1?', function()
      tree.version = 1
      notify('migrated to version 1')
      save_tree()
      M.check_or_update(tree, save_tree)
    end)
  end
end

-- Check whether the current tree is up-to-date and if not, prompt the user for any missing migration.
--
-- If it’s okay, return true.
M.check_or_update = function(tree, save_tree)
  local notify = require'mind.notify'.notify

  local check = M.check(tree)
  if check == M.Validation.UP_TO_DATE then
    return true
  elseif check == M.Validation.NEED_UPDATE then
    notify('the tree has a version higher than Mind’s; please update Mind', vim.log.levels.ERROR)
  elseif check == M.Validation.NEED_MIGRATION then
    notify('a migration is needed to be able to open this tree', vim.log.levels.WARN)
    M.migrate(tree, save_tree)
  end

  return false
end

return M
