# Confirm the creation of a tree

When no tree is available (global / local), we should prompt the user whether they want to create a tree or not. That is
important for local trees, because sometimes the CWD changes (thanks telescope…) and we start creating local trees in
completely unexpected places. It’s okay because we don’t save the local tree as long as no operation was made on it, but
still, we should ask for confirmation.
