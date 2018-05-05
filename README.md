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
displayed. Use F4 to swap the main tree and the reference tree.
When a tree becomes the reference tree it serves to
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

#### Working with Multiple Trees Segments

Tiny Tree Editor can work with your tree as separate segments instead of
one large tree. To create a segment, "tear off" a section of a tree.
Do this by selecting a node with the mouse by moving the mouse over the 
node, then while holding the left button down and holding the shift key down,
move the mouse away from the tree node into a clear area. When the desired
location is obtained, let the mouse button up.

When multiple segments are showing, clicking the segment with the mouse will
select it as the active segment. Once active, it will have both a selected
node (highlighted) and a current node where nodes are being added.
The active segment can also be moved around, independent of other segments,
by grabbing a node with the mouse and moving it. Place the mouse over a node,
then while holding the left mouse button down move the mouse to the new location,
then release the button.

Cutting and pasting nodes from one segment to another works. Segments can
also be joined. To join segments, place the head node of one tree over another
tree at the place to be joined. Now hold down the shift and enter tab to join
the first tree to the second as a sibling, or shift and enter to join the first
tree as a child of the second tree.

#### Using Work Spaces

Working spaces are organized as multiple pages using the Page Up and Page Down 
keys. An empty tree must be filled on the initial page. Once a tree segment
exists, the segment can be moved to another workspace. To do this, move the
mouse to a node of the desired segment and while holding the mouse left down,
use the Page Up or Page Down keys to switch to another workspace. Now left the
mouse button up and the segment will be placed in the new workspace.


