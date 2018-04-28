HOW TO USE THE STUFF IN THIS DIRECTORY

Stuff here allows one to generate midi files from a music description 
language that I have created. Tiny Tree Editor is used to create the musical score.
The convert.lua program is used to make the conversion to midi.

Convert.lua requires two things to be able to work: a link to classes.lua
from the parent directory, and libluamidi.so from my github project
"johndderry/libluamidi". You will need to compile/link the library from source.

The musical description language I call MDL for obvious reasons.
 
Stuff Index:
	convert.lua		Conversion program source
	m.j				MDL Reference source tree
	ex*.m			example MDL source trees
	music.alt		Half-baked manual as a source tree

These are the basic steps to generate midi files:

(1) Start up tte from this directory.

(2) Enter in a score from scratch or load an example

	Starting from scratch with reference tree and restrictive mode:

		Load m.j as an alternate load (shift-F1).
		Now swap trees with F4 to make the tree just loaded the reference tree. 
		Hit any key to clear the parse tree display.
		Turn on restrictive mode with shift-F4.
		Create your score in MDL

	Loading an example

		load the example from this directory with shift-F1
		modify the tree

	Save the new score or example with shift-F2 to myscore

(3) Run convert.lua to generate the midi file

	$ lua convert.lua myscore

	The output file is named 'out.mid'

