# tte
###(Tiny) Tree Editor

  * Create and edit a tree of nodes with this tool.
  * Nodes are a string of any characters including spaces.
  * Save and load to a readable, linearized text version.
  * Include free-form meaning text with each node.

1. Begin with an empty tree.
1. Type in the text of a new node.
1. Now type enter to accept text and continue with a child node,
   or tab to accept text and continue with a sibling node.
1. Enter optional meaning as text enclosed by curly braces.
1. Return to step 2 to continue adding nodes.

You may also:
  * Use the backspace key to remove the last node added.
  * Use the semicolon to switch from adding child nodes to
    adding sibling nodes, and to move position to a parent node.
  * Use the colon to switch from adding sibling nodes to adding
    child nodes, and to move position to a child node.
     
Once you have built up your tree you can go back and make changes.

  * Use the arrow keys and home to move the selected node 
     ( highlighted ) to your desired position. 
  * Use the backslash to begin editing the node in order to change
     the main text and/or meaning text.
  * Use the delete and insert keys to cut from the tree or paste into 
     the tree at the selected node using a paste buffer.

Save the tree into a text file with the F2 key, and load that tree back
with the F1 key. The file lists the nodes in an immediate descent
fashion, and the semicolon acts again as the indicator of a sibling
node to follow.

The editor tool can hold two trees in memory, but only one is being
displayed. The second tree is treated a reference tree and is not
displayed. When a tree becomes the reference tree, links are 
created pointing to it from the other tree. The F3 key is used to
swap the two trees.
