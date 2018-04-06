-------------------------------------------------------------
--    (Tiny) Tree Editor
--    Author: John Derry (johndderry@yahoo.com)
--    Version: 1.0
--    No Rights Reserved
-------------------------------------------------------------
require "classes"
LuaMidi = require "LuaMidi"

filename = "2.m"
if arg then
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  if #arg > 1 then filename = arg[1] end
end

Variables = {}

Notes = {
  a=0,b=1,c=2,d=3,e=4,f=5,g=6,aa=7,ab=8,ac=9,ad=10,ae=11,af=12,ag=13,
  ba=14,bb=15,bc=16,bd=17,be=18,bf=19,bg=20,ca=21,cb=22,cc=23,cd=24,ce=25,cf=26,cg=27,
  da=28,db=29,dc=30,dd=31,de=32,df=33,dg=34,ea=35,eb=36,ec=37,ed=38,ee=39,ef=40,eg=41,
  fa=42,fb=43,fc=44,fd=45,fe=46,ff=47,fg=48,ga=49,gb=50,gc=51,gd=52,ge=53,gf=54,gg=55,  
}

RevNotes = {
  'a','b','c','d','e','f','g','aa','ab','ac','ad','ae','af','ag',
  'ba','bb','bc','bd','be','bf','bg','ca','cb','cc','cd','ce','cf','cg',
  'da','db','dc','dd','de','df','dg','ea','eb','ec','ed','ee','ef','eg',
  'fa','fb','fc','fd','fe','ff','fg','ga','gb','gc','gd','ge','gf','gg',  
}

Digits = {
  ['0']=0, ['1']=1, ['2']=2, ['3']=3, ['4']=4, ['5']=5, ['6']=6, ['7']=7, ['8']=8, ['9']=9,
  ['10']=10, ['11']=11, ['12']=12, ['13']=13, ['14']=14, ['15']=15, ['16']=16, ['17']=17, ['18']=18, ['19']=19,
  ['20']=20, ['21']=21, ['22']=22, ['23']=23, ['24']=24, ['25']=25, ['26']=26, ['27']=27, ['28']=28, ['29']=29,
  ['30']=30, ['31']=31, ['32']=32, ['33']=33, ['34']=34, ['35']=35, ['36']=36, ['37']=37, ['38']=38, ['39']=39,
  ['40']=40, ['41']=41, ['42']=42, ['43']=43, ['44']=44, ['45']=45, ['46']=46, ['47']=47, ['48']=48, ['49']=49,
  ['50']=50, ['51']=51, ['52']=52, ['53']=53, ['54']=54, ['55']=55, ['56']=56, ['57']=57, ['58']=58, ['59']=59,
  ['60']=60, ['61']=61, ['62']=62, ['63']=63, ['64']=64, ['65']=65, ['66']=66, ['67']=67, ['68']=68, ['69']=69,
  ['70']=70, ['71']=71, ['72']=72, ['73']=73, ['74']=74, ['75']=75, ['76']=76, ['77']=77, ['78']=78, ['79']=79,
  ['80']=80, ['81']=81, ['82']=82, ['83']=83, ['84']=84, ['85']=85, ['86']=86, ['87']=87, ['88']=88, ['89']=89,
  ['90']=90, ['91']=91, ['92']=92, ['93']=93, ['94']=94, ['95']=95, ['96']=96, ['97']=97, ['98']=98, ['99']=99,
}

Operators = {
  ['+']=0, ['-']=1
}

Repeat = {
  ['&'] = 0
}

BuiltIn = {
  MODE = 0, KEY = 1
}

Modes = {}
Modes.ionian = {0,2,4,5,7,9,11,12}
Modes.dorian = {0,2,3,5,7,9,10}
Modes.phrygian = {0,1,3,5,7,8,10}
Modes.lydian = {0,2,4,6,7,9,11}
Modes.mixolydian = {0,2,4,5,7,9,10}
Modes.aeolian = {0,2,3,5,7,8,10}
Modes.locrian = {0,1,3,5,6,8,10}
Modes.index = { Modes.ionoan, Modes.dorian, Modes.phrygian, Modes.lydian, Modes.mixolydian, Modes.aeolian, Modes.locrian } 

TwelveNoteScale = {
  'C','C#','D','D#','E','F','F#','G','G#','A','A#','B','C','C#','D','D#','E','F','F#','G','G#','A','A#','B'
}

KeyDescriptor = {
  ['C']=0,['C#']=1,['D']=2,['D#']=3,['E']=4,['F']=5,['F#']=6,['G']=7,['G#']=8,['A']=9,['A#']=10,['B']=11
  }

Numerator = 4
Denominator = 16
Keyoffset = 0
Mode = Modes.ionian

outputNote = function( name, note, key, mode )
  if #note > 2 then
    io.write( "outputNote (" .. name .. ") pitch=" .. note[1]..'/'..note[2] .. " num=" .. note[3] .. " den=" .. note[4] .. '\n' ) 
  elseif #note > 1 then
    io.write( "outputNote (" .. name .. ") pitch=" .. note[1]..'/'..note[2] .. " num=" .. note[3] .. '\n' ) 
  else
    io.write( "outputNote (" .. name .. ") pitch=" .. note[1]..'/'..note[2] .. '\n' ) 
  end
  
  local nt, octave 
  if #note[1] > 1 then
    nt = Notes[ note[1]:sub(2,2) ]
    octave = Notes[note[1]:sub(1,1)] + 1
  else
    nt = Notes[ note[1]:sub(1,1) ]
    octave = 0
  end
  
  local midinote = mode[ tonumber( nt ) + 1]
  if Keyoffset + midinote > 11 then
    octave = octave + 1
  end
  local notestring = TwelveNoteScale[ midinote + 1 + Keyoffset ] .. octave

  local event = LuaMidi.NoteEvent.new({pitch=notestring})
  event:set_pitch( notestring )
  
  local num, den = note[3], note[4]
  if num < 0 then num = Numerator end
  if den < 0 then den = Denominator end
  local ticks = ( (num * 4) / den ) * 96
  
  event:set_duration( 'T' .. ticks )
  
  track:add_events( event )
  
end

noteDetail = function( node )
  
  local val = { node.name, Notes[node.name], -1, -1 }
  if node.child then
    val[3] = Digits[node.child.name]
    if node.child.child then
      val[4] = Digits[node.child.child.name]
    end
  end
  
  return val
end

setVariable = function( node )
  
  local val = Notes[node.child.name]
  if val == nil then
    val = Digits[node.child.name]
    if val == nil then
      val = Operators[node.child.name]
      if val ~= nil then
        val = evalAsOperator( node.child, node.name )
      else
        io.write( "error #1 in evalAsRepeat")
        val = { 'a', 0, 0, 0 }
      end
    else
      val = { '', val, 0, 0 }
    end
  else
    val = noteDetail( node.child )
  end
  
  Variables[node.name] = val
  return val
end

addOP = function( src, op )
  local a = src[2] + op[2]
  local b, c = src[3], src[4]
  if b < 0 and op[3] >= 0 then
    b = op[3]
  end
  if c < 0 and op[4] >= 0 then
    c = op[4]
  end
  return { RevNotes[a+1], a, b, c }
end

subOP = function( src, op )
  local a = src[2] - op[2]
  local b, c = src[3], src[4]
  if b < 0 and op[3] >= 0 then
    b = op[3]
  end
  if c < 0 and op[4] >= 0 then
    c = op[4]
  end
  return { RevNotes[a+1], a, b, c }
end

evalAsOperator = function( node, otype )

  local first
  if Operators[node.name] then
    first = evalAsOperator( node.child, node.name )
  elseif Notes[node.name] then
    first = noteDetail( node )
  elseif Digits[node.name] then
    first = { Digits[node.name], -1, -1 }
  else
  -- consider as variable
    first = Variables[node.name]
    if not first then first, Variables[node.name] =  {'a',0,-1,-1}, {'a',0,-1,-1} end
    if node.child then
      -- set the variable
      first = setVariable( node )        
    end
  end
  
  node = node.next
  while node do
    local nextone
    
    if Operators[node.name] then
      nextone = evalAsOperator( node.child, node.name )
    elseif Notes[node.name] then
      nextone = noteDetail( node )
    elseif Digits[node.name] then
      first = { Digits[node.name], 1, 1 }
    else
    -- consider as variable
      nextone = Variables[node.name]
      if not nextone then nextone, Variables[node.name] =  {'a',0,-1,-1}, {'a',0,-1,-1} end
      if node.child then
        -- set the variable
        nextone = setVariable( node )        
      end
    end
    if otype == '+' then
      first = addOP( first, nextone )
    elseif otype == '-' then
      first = subOP( first, nextone )
    end
    node = node.next
  end
  
  return first
end

evalAsBuiltIn = function( node, btype )
  
  if btype == "MODE" then
    if node then Mode = Modes.index[tonumber(node.name)] end
  elseif btype == "KEY" then
    if node then Keyoffset = KeyDescriptor[node.name] end
  end
  
end

evalAsRepeat = function( node, rtype )
  
  local rep = tonumber( node.name )
  node = node.next
  local val, savenode = nil, node
  
  while rep > 0 do
    node = savenode
    while node do
      val = Notes[node.name]
      if val ~= nil then
        val = noteDetail( node )
        outputNote( node.name, val, Keyoffset, Mode ) 
        
      elseif Operators[node.name] then
        outputNote( evalAsOperator( node.child, node.name, Mode ), node.name )
        
      elseif Repeat[node.name] then
        evalAsRepeat( node.child, node.name )
        
      elseif BuiltIn[node.name] then
        evalAsBuiltIn( node.child, node.name )
        
      else
        -- consider as variable
        val = Variables[node.name]
        if not val then val, Variables[node.name] =  {'a',0,-1,-1}, {'a',0,-1,-1} end
        if node.child then
          -- set the variable
          setVariable( node )        
        else
          -- read the variable
          outputNote( node.name, val, Key, Mode )
        end
      end
      node = node.next
    end
    rep = rep - 1
  end
  return 0  
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

track = LuaMidi.Track.new()

musictree = readtree()
dumptree( musictree.root, '' )

evalAsRepeat( musictree.root, "initial" )

writer = LuaMidi.Writer.new( track )

writer:save_MIDI('testmidi')
