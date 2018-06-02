local Variables = {}

local Notes = {
  a=0,b=1,c=2,d=3,e=4,f=5,g=6,aa=7,ab=8,ac=9,ad=10,ae=11,af=12,ag=13,
  ba=14,bb=15,bc=16,bd=17,be=18,bf=19,bg=20,ca=21,cb=22,cc=23,cd=24,ce=25,cf=26,cg=27,
  da=28,db=29,dc=30,dd=31,de=32,df=33,dg=34,ea=35,eb=36,ec=37,ed=38,ee=39,ef=40,eg=41,
  fa=42,fb=43,fc=44,fd=45,fe=46,ff=47,fg=48,ga=49,gb=50,gc=51,gd=52,ge=53,gf=54,gg=55,  
}

local RevNotes = {
  'a','b','c','d','e','f','g','aa','ab','ac','ad','ae','af','ag',
  'ba','bb','bc','bd','be','bf','bg','ca','cb','cc','cd','ce','cf','cg',
  'da','db','dc','dd','de','df','dg','ea','eb','ec','ed','ee','ef','eg',
  'fa','fb','fc','fd','fe','ff','fg','ga','gb','gc','gd','ge','gf','gg',  
}

local Digits = {
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

local Operators = {
  ['+']=0, ['-']=1
}

local Block = {
  ['@'] = 0, ['&'] = 1
  }
  
local BuiltIn = {
  KEY = 0, MODE = 1, CHANNEL = 2, PROGRAM = 3, VELOCITY = 4, TEMPO = 5
}

local Modes = {}

Modes.ionian = {0,2,4,5,7,9,11}
Modes.dorian = {0,2,3,5,7,9,10}
Modes.phrygian = {0,1,3,5,7,8,10}
Modes.lydian = {0,2,4,6,7,9,11}
Modes.mixolydian = {0,2,4,5,7,9,10}
Modes.aeolian = {0,2,3,5,7,8,10}
Modes.locrian = {0,1,3,5,6,8,10}
Modes.index = { Modes.ionian, Modes.dorian, Modes.phrygian, Modes.lydian, Modes.mixolydian, Modes.aeolian, Modes.locrian } 

local TwelveNoteScale = {
  'C','C#','D','D#','E','F','F#','G','G#','A','A#','B','C','C#','D','D#','E','F','F#','G','G#','A','A#','B'
}

local KeyDescriptor = {
  ['C']=0,['C#']=1,['D']=2,['D#']=3,['E']=4,['F']=5,['F#']=6,['G']=7,['G#']=8,['A']=9,['A#']=10,['B']=11
  }

local Numerator = 4
local Denominator = 4
local Keyoffset = 0
local Channel = 0
local Velocity = 127
local Time = 0
local Mode = Modes.ionian

local outputProgCng = function( program )
  io.write( "outputProgChange program=" .. program .. '\n' ) 
  
  alsa.sendprogram( Channel, program, Time )
  
end  

local outputNote = function( name, note )
  if #note > 2 then
    io.write( "outputNote (" .. name .. ") pitch=" .. note[1]..'/'..note[2] .. " num=" .. note[3] .. " den=" .. note[4] ) 
  elseif #note > 1 then
    io.write( "outputNote (" .. name .. ") pitch=" .. note[1]..'/'..note[2] .. " num=" .. note[3] ) 
  else
    io.write( "outputNote (" .. name .. ") pitch=" .. note[1]..'/'..note[2] ) 
  end
  
  local nt, octave 
  if #note[1] > 1 then
    nt = Notes[ note[1]:sub(2,2) ]
    octave = Notes[note[1]:sub(1,1)] + 1
  else
    nt = Notes[ note[1]:sub(1,1) ]
    octave = 0
  end
  
  local midinote = Mode[ tonumber( nt ) + 1]
--  if Keyoffset + midinote > 11 then
--    octave = octave + 1
--  end
  
  local num, den = note[3], note[4]
  if num < 0 then num = Numerator end
  if den < 0 then den = Denominator end
  
  io.write(" on tick="..Time )
  alsa.sendnoteon( Channel, midinote + octave*12 + Keyoffset, Velocity, Time )

  Time = Time + ( num / den ) * 96
  
  io.write(" off tick="..Time..'\n' )
  alsa.sendnoteoff( Channel, midinote + octave*12 + Keyoffset, Velocity, Time )
  
end

local noteDetail = function( node )
  
  local val = { node.name, Notes[node.name], -1, -1 }
  if node.child then
    val[3] = Digits[node.child.name]
    val[3] = val[3] or 0
    if node.child.child then
      val[4] = Digits[node.child.child.name]
      val[4] = val[4] or 0
    end
  end
  
  return val
end

local setVariable = function( node )
  
  local val = Notes[node.child.name]
  if val == nil then
    val = Digits[node.child.name]
    if val == nil then
      val = Operators[node.child.name]
      if val == nil then
        val = Block[node.child.name]
        if val == nil then
          io.write( "error in setVariable: don't recognize '" .. node.child.name .. "'\n" )
          val = { 'a', 0, -1, -1 }
        else
          val = {'a', 0, -1, -1, node.child }
        end
      else
        val = evalAsOperator( node.child, node.name )
      end
    else
      val = { '', val, -1, -1 }
    end
  else
    val = noteDetail( node.child )
  end
  
  Variables[node.name] = val
  return val
end

local addOP = function( src, op )
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

local subOP = function( src, op )
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
      nextone = { Digits[node.name], 1, 1 }
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

local evalAsBuiltIn = function( node, btype )
  
  if node == nil then return end
  
  if btype == "KEY" then Keyoffset = KeyDescriptor[node.name]
  elseif btype == "MODE" then Mode = Modes.index[tonumber(node.name)]
  elseif btype == "CHANNEL" then Channel = tonumber(node.name) -1
  elseif btype == "PROGRAM" then outputProgCng( tonumber(node.name) -1 )
  elseif btype == "VELOCITY" then Velocity = tonumber(node.name) 
  elseif btype == "TEMPO" then alsa.tempo( tonumber(node.name) ) 
  end

end

local function evalAsParallel( node, ptype )
  
  local val
  local save = { Numerator, Denominator, Keyoffset, Channel, Time, Mode }
  while node do
    
    Numerator, Denominator, Keyoffset, Channel, Time, Mode = save[1], save[2], save[3], save[4], save[5], save[6]
    
    if Notes[node.name] then
      outputNote( node.name, noteDetail( node ) ) 
      
    elseif Operators[node.name] then
      outputNote( node.name, evalAsOperator( node.child, node.name ) )
      
    elseif Block[node.name] == 0 then
      evalAsRepeat( node.child, node.name )
      
    elseif Block[node.name] == 1 then
      evalAsParallel( node.child, node.name )
      
    elseif BuiltIn[node.name] then
      evalAsBuiltIn( node.child, node.name )
      
    else
      -- consider as variable, but don't set
      val = Variables[node.name]
      if val then -- read the variable
        if val[5] then
          evalAsRepeat( val[5].child, val[5].name )    
        else
          outputNote( node.name, val )
        end
      end
    end
    node = node.next
  end
  return 0  
end    

function evalAsRepeat( node, rtype )
  
  local rep, val
  if Digits[node.name] then
    rep = tonumber( node.name )
  elseif Operators[ node.name ] then
    rep = evalAsOperator( node.child, node.name )
  else
    val = Variables[node.name]
    if val then rep = val[2] end
  end
  if rep == nil then rep = 1 end
  
  node = node.next
  local savenode = node
  
  while rep > 0 do
    node = savenode
    while node do
      if Digits[node.name] then
        Numerator = tonumber( node.name )
        if node.child then
          Denominator = tonumber( node.child.name )
        end              
      elseif node.name == '*' then
        if node.child then
          local num = tonumber( node.child.name )
          if node.child.child then
            local den = tonumber( node.child.child.name )
            Time = Time + ( (num * 4) / den ) * 96
          else
            Time = Time + ( (num * 4) / Denominator ) * 96
          end
        else
            Time = Time + ( (Numerator * 4) / Denominator ) * 96
        end
      elseif Notes[node.name] then
        outputNote( node.name, noteDetail( node ) ) 
        
      elseif Operators[node.name] then
        outputNote( node.name, evalAsOperator( node.child, node.name ) )
        
      elseif Block[node.name] == 0 then
        evalAsRepeat( node.child, node.name )
      
      elseif Block[node.name] == 1 then
        evalAsParallel( node.child, node.name )
      
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
          if val[5] then
            evalAsRepeat( val[5].child, val[5].name )    
          else
            outputNote( node.name, val )
          end
        end
      end
      node = node.next
    end
    rep = rep - 1
  end
  
  return 0  
end    

local function evalAsList( node, rtype )
  
  local val
  while node do
    if Digits[node.name] then
      Numerator = tonumber( node.name )
      if node.child then
        Denominator = tonumber( node.child.name )
      end              
    elseif node.name == '*' then
      if node.child then
        local num = tonumber( node.child.name )
        if node.child.child then
          local den = tonumber( node.child.child.name )
          Time = Time + ( (num * 4) / den ) * 96
        else
          Time = Time + ( (num * 4) / Denominator ) * 96
        end
      else
          Time = Time + ( (Numerator * 4) / Denominator ) * 96
      end
    elseif Notes[node.name] then
      outputNote( node.name, noteDetail( node ) ) 
      
    elseif Operators[node.name] then
      outputNote( node.name, evalAsOperator( node.child, node.name ) )
      
    elseif Block[node.name] == 0 then
      evalAsRepeat( node.child, node.name )
    
    elseif Block[node.name] == 1 then
      evalAsParallel( node.child, node.name )
    
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
        if val[5] then
          evalAsRepeat( val[5].child, val[5].name )    
        else
          outputNote( node.name, val )
        end
      end
    end
    node = node.next
  end
  
  return 0  
end    

local collector = {}
local collcount, collfirst = 0, true
local lasttime

local function noteon( chan, pitch, veloc, time )
  --io.write("converter.noteon() collfirst="..tostring(collfirst).." collcount="..tostring(collcount).."\n")
  collector[pitch] = time
  collcount = collcount + 1
end

local function adjusttime( time )
  local r
  if time % 96 then
    r = time % ( 96 / Denominator )
    if r > 96 / ( Denominator * 2 ) then
      time = time + ( 96 / Denominator ) - r
    else 
      time = time - r
    end
  end
  return time
end
  
local function create_note( starttime, endtime, pitch, veloc )
  -- adjust times to grid based on current Denominator
  starttime = adjusttime( starttime )
  endtime = adjusttime( endtime )
  if starttime == endtime then return end
  
  --find the note this pitch represents
  pitch = pitch - Keyoffset
  local octave = math.floor(pitch / 12)
  local noteoffs = pitch % 12
  local note, n = nil 
  for n = 1, 7 do
    if noteoffs == Mode[n] then
      if octave > 0 then
        note = RevNotes[octave]
      else
        note = ""
      end
      note = note .. RevNotes[n]
      break
    end
  end
  
  if note == nil then return end
  
  Syntax.tree.current = Syntax.nextState( note, Syntax.tree.current )
  Syntax.tree.current = Syntax.nextState( '\n', Syntax.tree.current )

  local numerator = (endtime - starttime) / ( 96 / Denominator )  
  Syntax.tree.current = Syntax.nextState( tostring( numerator), Syntax.tree.current )
  
  Syntax.tree.current = Syntax.nextState( '\t', Syntax.tree.current )
  Syntax.tree.current = Syntax.nextState( '\t', Syntax.tree.current )
    
end

local function create_rest( starttime, endtime )
  -- adjust times to grid based on current Denominator
  starttime = adjusttime( starttime )
  endtime = adjusttime( endtime )
  if starttime == endtime then return end
    
  Syntax.tree.current = Syntax.nextState( '*', Syntax.tree.current )
  Syntax.tree.current = Syntax.nextState( '\n', Syntax.tree.current )

  local numerator = (endtime - starttime) / ( 96 / Denominator )  
  Syntax.tree.current = Syntax.nextState( tostring( numerator), Syntax.tree.current )
  
  Syntax.tree.current = Syntax.nextState( '\t', Syntax.tree.current )
  Syntax.tree.current = Syntax.nextState( '\t', Syntax.tree.current )
    
end

local function noteoff( chan, pitch, veloc, time )
  local starttime
  --io.write("converter.noteoff() collfirst="..tostring(collfirst).." collcount="..tostring(collcount).."\n")
  --if collfirst and collcount == 1 then
  if collfirst then
    collfirst = false
    starttime = collector[pitch] - collector[pitch] % 96
    if collector[pitch] > starttime then
      create_rest( starttime, collector[pitch] )
    end
    create_note( collector[pitch], time, pitch, veloc )
    collector[pitch] = nil
    collcount = collcount - 1
    lasttime = time
    return
  end
  starttime = lasttime
  if collector[pitch] > starttime then
    create_rest( starttime, collector[pitch] )
  end
  create_note( collector[pitch], time, pitch, veloc )
  collector[pitch] = nil
  collcount = collcount - 1
  lasttime = time  
end

local function set_first()
  collfirst = true
  collector = {}
  collcount = 0
  --io.write("converter.first() capture="..tostring(capturemode).."\n")
end

local function reset(time)
  collector = {}
  Numerator = 4
  Denominator = 4
  Keyoffset = 0
  Channel = 0
  Velocity = 127
  Time = time
  Mode = Modes.ionian
end

local convertmidi = {}

convertmidi.reset = reset
convertmidi.evalAsRepeat = evalAsRepeat
convertmidi.evalAsParallel = evalAsParallel
convertmidi.evalAsList = evalAsList

convertmidi.noteon = noteon
convertmidi.noteoff = noteoff
convertmidi.first = set_first

return convertmidi
