CFLAGS = -g -O0 -fPIC 
LDFLAGS = -g

LIBRARY = libluaalsa.so
OBJECTS = lualib.o midi.o

$(LIBRARY): $(OBJECTS)
	gcc -shared -o $(LIBRARY) $(OBJECTS) $(LDFLAGS)
	
lualib.o: lualib.c
	gcc -c $(CFLAGS) -I/usr/include/luajit-2.0 lualib.c

midi.o: midi.c
	gcc -c $(CFLAGS) midi.c

clean:
	(rm -f *.o $(LIBRARY))

