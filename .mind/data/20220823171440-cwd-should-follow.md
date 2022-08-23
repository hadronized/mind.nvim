# cwd should follow

To fix that issue, we probably need to fix the state, first. Loading and saving the state is a bit of a pain right now,
because we should only save the state of the tree we are currently working on (protip: at some point we might even want
to support different trees when e.g. moving nodes from one tree to another).

# Let’s fix the state

The state is a bit complex. `mind.state.state` is the « main » state. `mind.state.local_tree` is the local tree.
Basically, the `wrap*` functions should run the function and check its return. That return could be a bool for now. If
it’s true, it means the tree needs to be saved. That could be the first enhancement.

Then, the real problem is that project-based trees need to know when they need to create a new tree, or when they don’t.
For that, we need a loading function that loads the tree from cwd. If after that function `mind.state.local_tree` is
empty, then we can create a new tree.

So yeah, we need to fix the tree.
