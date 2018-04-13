# tte
### (Tiny) Tree Editor

  * Create and edit a tree of nodes with this tool.
  * Nodes are a string of any characters including spaces.
  * Save and load to a readable text version.
  * Include additional meaning text with each node.
  * Access additional language features.

1. Begin with an empty tree.
1. Type in the text of a new node.
1. Now type enter to accept text and continue with a child node,
   or tab to accept text and continue with a sibling node.
1. Enter optional meaning as text enclosed by curly braces.
1. Return to step 2 to continue adding nodes.

You may also:
  * Use the tab key to switch from adding child nodes to
    adding sibling nodes, and to move position to a parent node.
  * Use the enter key to switch from adding sibling nodes to adding
    child nodes, and to move position to a child node.
  * Use the shifted backspace key to remove the last node added as 
    well as sibling and parent nodes. Care should be used here.
     
Once you have built up your tree you can go back and make changes.

  * Use the arrow and home keys or click with the mouse to move
    the selected node ( highlighted ) to your desired position.
  * Or is F3 key to search for a node with search text.
  * Use the backslash to begin editing the node in order to change
    the main text and/or meaning text.
  * Use the delete and insert keys to cut from the tree or paste into 
    the tree at the selected node using a paste buffer.
  * Use the end key to return view to append position.
  * Drag the entire tree around by grabbing blank area with the mouse. 
  * Use backslash to view selected node then backslash to return.

Save the tree into a text file with the F2 key, and load that tree back
with the F1 key. The output file lists the nodes and meanings delimited
by tab and newline characters. Shifted function keys for JSON style.

The editor tool can hold two trees in memory, but only one is being
displayed. The second tree is treated a reference tree and is not
displayed. When a tree becomes the reference tree it serves to
provide additional relationships, and possible restrict what can be 
entered into the main tree nodes. Shifted F4 toggles entry restriction.

#### Restricted Entry and Hyper Mode

When restrictive entry has been activated with shifted F4, only entries
which match an example in the reference tree are allowed. The color 
of the cursor informs you of the validity of what is typed. Green means
the input so far is accepted, red indicates an erroneous input. Further-
more, when the entry exactly matches a valid example the typed text 
becomes green. Only at this point will the tab or enter key be accepted.

To use restrictive entry first create your example tree. Organize the tree
as you see fit, include labeling nodes prefixed with a ‘ #’. Now use F4
to make the example tree just created become the reference tree.
Then use shifted F4 to enter restrictive entry mode.

Once in restrictive mode, you can call up a list possible entries which
are valid to be entered, based on what you have entered so far. Use the 
right arrow key to call up hyper mode. Immediately you will see the first
possibility presented, where the completion text is highlighted as part 
of the cursor. Use tab or enter key to accept this offer, of use the
up and down arrow keys to call up all other possible completions.
