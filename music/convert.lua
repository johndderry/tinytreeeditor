-------------------------------------------------------------
--    (Tiny) Tree Editor
--    Author: John Derry (johndderry@yahoo.com)
--    Version: 1.0
--    No Rights Reserved
-------------------------------------------------------------
require "classes"
MidiLib = require "libluamidi"
ToMidi = require "tomidi"

ToMidi.setmidilib( MidiLib )

filename = "ex1.m"
if arg then
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  if #arg > 0 then filename = arg[1] end
end

dumptree = function( node, indent ) 
  
  io.write( indent .. "Node: " .. node.name .. '\n' )
  
  if node.child then dumptree( node.child, '  ' .. indent ) end
    
  if node.next then dumptree( node.next, indent ) end
end

nextToken = function( chunk )
  
  local start, finish, quoted = 1, 1, false
  while start < #chunk do
    local s = string.sub( chunk, start, start )
    if s ~= ' ' and s ~= ',' then break end
    start = start+1
  end
  if start == #chunk then return nil end
  if string.sub( chunk, start, start ) == '"' then 
    start = start + 1 
    quoted = true
  end
  finish = start
  while finish <= #chunk do
    local c = string.sub( chunk, finish, finish )
    if quoted then
      if c == '"' then break end
    elseif c == ' ' or c == ':' or c == ';' or c == '}' or c == '\n' then 
      break
    end
    finish = finish+1
  end
  local restof = finish + 1
  if quoted then finish = finish -1 end
    
  return string.sub( chunk, start, finish ), string.sub( chunk, restof )
end
  
altload = function( parent, chunk )
  
  local node, token = SynNode:new( parent )
  
  local indx = string.find( chunk, '{')
  chunk = string.sub( chunk, indx+1 )
  
  while true do
    token, chunk = nextToken( chunk )
    if token == '}' then break
    elseif token == "name:" then    node.name, chunk = nextToken( chunk )
    elseif token == "meaning:" then node.meaning, chunk = nextToken( chunk )
    elseif token == "next:" then    node.next, chunk = altload( parent, chunk )
    elseif token == "child:" then   node.child, chunk = altload( node, chunk )
    end
  end
  return node, chunk
end

readtree = function()
  
  local file = io.open(filename, "r")
  if file == nil then
    io.write("!!failure to read!!")
    return nil
  end
  local ss = file:read("*all");
  file:close()

  local tree = SynTree.new()  
  local indx = string.find( ss, '{' )

  tree.root = altload( nil, string.sub( ss, indx ) )
  tree:fixLinks( nil, nil, tree.root )
  tree.select = tree.root
  tree.select.selected = true
  tree.current = tree:outerChild( tree.root )

  return tree
end

--track = LuaMidi.Track.new()
sortednotes = MidiLib.SortedNotesNew()
ToMidi.setsortednotes( sortednotes )

musictree = readtree()
dumptree( musictree.root, '' )

start = musictree.root
while start and start.name:sub(1,1) == '#' do start = start.child end

ToMidi.evalAsRepeat( start, "initial" )

--writer = LuaMidi.Writer.new( track )
--writer:save_MIDI('testmidi')

count = MidiLib.SortedNotesCount( sortednotes )

track = MidiLib.TrackNew( 6*count + 2 )

MidiLib.SortedNotesTrackNotes( sortednotes, track )

tracklen = MidiLib.TrackLength( track ) 

midifile = MidiLib.MidiFileNew("out.mid", "w")

MidiLib.MidiFileWriteChunk( midifile, track );

MidiLib.SortedNotesDelete( sortednotes )

MidiLib.TrackDelete( track )

MidiLib.MidiFileDelete( midifile )

io.write( 'count='.. count .. '  tracklen=' .. tracklen .. '\n')
