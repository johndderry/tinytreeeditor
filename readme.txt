README for (Tiny) Tree Editor

This application runs on the LOVE2d game engine. See http://love2d.org homepage for more
information and to download the engine for various platforms. It is needs to run on LOVE 11.x

In addition, if the midi capabilities are desired it also requires a supplied alsa interface
library, libluaalsa. This library requires alsa and luajit-2.0 development headers.
Execute make to build this library.

You can run the editor application by starting the love engine while pointing it to the 
application tte.love. How this is done does depends on your platform, generally you can 
drop the application icon onto the love engine application to start. 

It can also be started from the command line by executing the love2d application and 
supplying tte.love as the first argument. This appication looks for three arguments:
  --fontsize size
  --width screen_width
  --heigth screen_height

Alternately, you can place all the project files in a directory, then point the love engine
to that directory. If you have built the libluaalsa library, this is how you must do it.
From that directory, the command would be "love . [arguments]".
