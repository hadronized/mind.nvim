# Add a node to parent

Something that is often wanted is to add a node inside a parent while the cursor is not on the parent. I think that this
should be the default. Then, it means: how do we add a node to a leaf (making it a parent)? We could use `a` to « add to
current parent » and `A` to « make it a parent and add in.

Or actually:

- `a`: _around_, so it adds to the parent.
- `i`: _inside_, so adds in the node under the cursor.

I like that idea. And finally, we are going to do the same thing as we did with the move feature:

- `o`: add a node _below_ the current node, still in the same parent.
- `O`: add a node above the current node, still in the same parent.
- `i`: add a node in the current node.

Because those keys are overriden for move and now add, we will need to introduce the concept of keymaps before being
able to go on.
