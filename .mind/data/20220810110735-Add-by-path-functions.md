# Add by_path functions

We want to be able to expose a small Lua API to do stuff by using paths. For instance, my journaling workflow is simple:
everyday, I want to open my “daily journal”, which is basically an entry in the tree. If we are the 10 Aug 2022, I want
to be able to open the data at the node `/Journal/2022/Aug/10`.

In order to do that, we need a couple of stuff to be done first (nested to this very issue).

1. We need to be able to get a node by path. Getting a node by path should have an option that says whether intermediate
   nodes should be automatically created if not present already. That’s super important for the journaling workflow, for
   instance.
2. We need to be able to run a couple of actions for a given path. The way it would work is basically have a Lua API for
   nodes (like rename, delete, open data, etc.).
