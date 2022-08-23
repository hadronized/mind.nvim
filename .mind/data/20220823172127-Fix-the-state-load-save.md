# Fix the state (load / save)

We want to remove `load_state` and `save_state` from `mind.state`. Or actually, we still might want to use it, and it
would save everything. Instead, we want to have `load_main_state` / `load_project_state` and same for save functions.

With that, we can fix the `wrap*` functions to call the right thing (and we don’t need to load at the setup of the
plugin anymore, so it’s lazier == better).
