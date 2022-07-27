# mind.lua, a plugin for notetaking and task workflows

This plugin is a new take on note taking and task workflows. The idea is derived from using several famous plugins, such
as [org-mode] or even standalone applications, like [Notion].

<!-- vim-markdown-toc GFM -->

* [Presentation](#presentation)

<!-- vim-markdown-toc -->

# Presentation

The plugin is based on a simple concept yet powerful one: trees. A tree is a special kind of graph. In that graph, every
node can have as many children as they want, and there is only one parent for each children. The graph holds itself
completely with the root node, which has the children nodes making the rest of the graph.

That concept is really powerful because it can be applied to almost everything in life. A list is a flat graph (with
depth = 1). A software project could be seen as a graph, where the top node is the project itself, and sub-projects are
children nodes. At a deep enough stage, you find code files, and you can still imagine that those files have children
(the actual code AST), etc. etc.

Ideas, notes, tasks, etc. can also be imagined as being part of such a graph. We have a natural tendency to want to tidy
things by classifying them. For instance, you might have two ideas that both belong to “Infrastructure”, and you also
have a couple of meeting notes that could be put in a “Meeting” node.

This plugin generalizes the concept of graph to allow people to create mind graphs. A mind graph has the following
properties:

- Each node is either a tree or a leaf.
- A tree has a name and from 0 to many children.
- A leaf has a name and is either a file or a special mind object. More on that later.

Any kind of node has a _path_ in the mind tree. That path is simply the concatenation of its transitive parents’ names
with its own name. For instance, in the following tree:

```
v a
  > b
  v c
    > e
  > d
```

`a`’s path is `/a`, `b`’s path is `/a/b` and `e`’s path is `/a/c/e`.

As said earlier, leaves can be different things. A file leaf is simply a node that points to a file. The name of the file
is a unique name and is not related to its node name. Hence, file name are automatically generated, and the files don’t
have to follow a tree-like structure (we actually don’t really care about that property).

A leaf can also be a functional node. Functional nodes are nodes that compute their names and content on the fly, when
we try to expand them. For instance, we could imagine a functional node at `/Journal/Today` that would compute the
current date and would return the node at the path `/Journal/{year}/{month}/{day}`. If that node doesn’t exist, it would
create it, insert it in the tree and return it.

Functional nodes allow to build more complex workflows, such as `/Tasks/Critical`, that would get all the current tasks,
filter them by criticical state and would build a node with only those tasks. That last point leads us to the last kind
of node: link nodes.

A link node is simply a node that points to another one. In that sense, a link node simply has a name, and its content
is simply a path. Link nodes do not point to files; only other nodes.

Because people will want to generate links for note taking, it’s important to provide some functions to automatically
generate links. Imagine you have opened a file node at `/Notes/Technical/Language/Rust` and you want to reference
`/Notes/Technical/Language/C`. Instead of manually looking for the associated file, all you have to do is to call the
function that will automatically pick the file name for you. That’s pretty simple: you give it the path, it gives back
the file name and insert it (it could support Markdown by default). The link would be something like:

```markdown
[description of the link](/some/path/id-of-the-node)
```

A function could be provided to migrate links automatically if the prefix changes.

[org-mode]: https://orgmode.org/
[Notion]: https://www.notion.so/
