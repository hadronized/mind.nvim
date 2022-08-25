# In-memory index of nodes

I want an in-memory indexing of nodes. The way it would work is simple. Take a node, like `/Foo/Bar/Zoo`. That node has
three segments in its paths. Each segment is actually a node:

- `/Foo` is a node.
- `/Foo/Bar` is also a node.
- `/Foo/Bar/Zoo` is another node.

So basically, to index a tree, we simply need to build up the path (not as a string, more as a list so that we can
easily append / pop). For each segment part, we need to add to the index the node.

## What is the index?

Super simple and stupid, the index is a simple `segment -> [node]` mapping. So `/Foo/Bar` will be present in two entries
in the index: `Foo`, and `Bar`.

## Allez plus haut™

We can break down the index by… breaking down segment names. Basically, for a given segment `Foo`, we can break that
name into three components:

- `Foo`, that must have an entry for that node.
- `Fo`, which is the beginning of the node.
- `oo`, which is the end.

For a longer name, like `I love dogs`, we need to decide when to stop. Basically, we should index words, 2-seq, 3-seq…
and more? When to stop? That should probably be configurable.

If we don’t set a limit, this is going to explode quite quickly in memory and it’s unlikely to be very useful because of
the very quickly decreasing entropy. There won’t be a lot of entries with `e dog`.

So, we can probably remove whitespaces and shit, and simply build from 2 to N sequences, with N set to like 5 by
default.

Once this is done, we will have a nice super fast index to lookup in.

`strcharpart` can be used to slice and generate the N-graphs.
