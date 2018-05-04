-------------------------------------------------------------
--    (Tiny) Tree Editor
--    Author: John Derry (johndderry@yahoo.com)
--    Version: 1.0
--    No Rights Reserved
-------------------------------------------------------------
require "classes"
require "objects"

MyShift = {[","]="<", ["."]=">", ["/"]="?", [";"]=":", ["'"]='"', 
           ["["]="{", ["]"]="}", ["\\"]="|",["`"]="~", ["1"]="!", ["2"]="@",
           ["3"]="#", ["4"]="$", ["5"]="%", ["6"]="^",
           ["7"]="&", ["8"]="*", ["9"]="(", ["0"]=")", ["-"]="_", ["="]="+" }
blurb = 3
scrollX, scrollY = 0, 0
definition, filename, searchstr, message = "", "", "", nil
shift, defmode, editmode, autoscroll = false, false, false, true
floadmode, fsavemode, falt, searchmode, mousehold = false, false, false, false, false
showkeyparse, showlist = false, false

if allegro then
  sys = require "allegrodef"
elseif love then
  sys = require "lovedef"
else
  return
end

function adjustSelectScroll()
  
  autoscroll = false
    
  while Syntax.tree.select.x > screenX*0.8 or Syntax.tree.select.x < 8 or
      Syntax.tree.select.y > screenY*0.8 or Syntax.tree.select.y < treeYbegin do
    
    if Syntax.tree.select.x > screenX*0.8 then
      scrollX = scrollX - screenX*0.2 
    elseif Syntax.tree.select.x < 8 then
     scrollX = scrollX + screenX*0.1
    end
    if Syntax.tree.select.y > screenY*0.8 then
      scrollY = scrollY - screenY*0.2 
    elseif Syntax.tree.select.y < treeYbegin then
      scrollY = scrollY + screenY*0.1
    end
    
    Syntax.tree:setRowPosition( 10 + scrollX, treeYbegin + scrollY, Syntax.tree.root, sys.getwidth )
  end
end

---------------------------------------------------------------------
-- key event handlers
---------------------------------------------------------------------

function sys.keypressed( key )
  if key == sys.leftshift or key == key.rightshift then
    shift = true
  end
  showkeyparse = false
end

function sys.keyreleased( key ) 
  local p = Syntax.tree.select
    
  if key == sys.leftshift or key == sys.rightshift then
    shift = false
    return
  end
  
  if Keystroke.state == "pass" then  
    if key == sys.home and p then
      --p.selected = false
      --Syntax.tree.select = Syntax.tree.root
      --Syntax.tree.select.selected = true
      adjustSelectScroll()
      return
    end
    if key == sys._end then
      autoscroll = true
      return
    end
    if ((key == key.down and not showlist) or (key == sys.right and showlist)) 
          and p and p.child then
      p.selected = false
      p = p.child
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
    if ((key == sys.up and not showlist) or (key == sys.left and showlist))
          and p and p.parent then
      p.selected = false
      p = p.parent
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
    if ((key == sys.left and not showlist) or (key == sys.up and showlist))
          and p and p.prev then
      p.selected = false
      p = p.prev
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
    if ((key == sys.right and not showlist) or (key == sys.down and showlist))
        and p and p.next then
      p.selected = false
      p = p.next
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
  end
  
  if key == sys.delete and Syntax.tree.select then
    local newselect = Syntax.tree.select.prev
    if newselect == nil then newselect = Syntax.tree.select.parent end
    if newselect == nil then return end
    
    if Syntax.tree.select == Syntax.tree.current then
      Syntax.tree.current = newselect
    end
    
    Syntax.tree.select.selected = false
    Syntax.tree:cut( Syntax.tree.select )
    Syntax.tree.select = newselect
    newselect.selected = true
    return
  end
  if key == sys.insert and Syntax.tree.cutbuffer then
    Syntax.tree:paste( Syntax.tree.select )
    return
  end
  
  if key == sys.f1 then
    floadmode = true
    if shift then falt = true end
    return
  end
  if floadmode then
    if key == sys._return then
      floadmode = false
      local file = io.open(filename, "r")
      if file == nil then
        message = "!!failure to read!!"
        return
      end
      local ss = file:read("*all"); file:close()
      Syntax.tree.root = nil
      if falt then
        local indx = string.find( ss, '{' )
        Syntax.tree.root = Syntax.altload( nil, string.sub( ss, indx ) )
        Syntax.tree:fixLinks( nil, nil, Syntax.tree.root )
        Syntax.tree.select = Syntax.tree.root
        Syntax.tree.select.selected = true
        Syntax.tree.current = Syntax.tree:outerChild( Syntax.tree.root )
        Syntax.state = "desc"
      else
        Syntax.load( ss )
      end
      falt = false
      return
    elseif key == sys.escape then
      floadmode, falt = false, false
      return
    elseif key == sys.backspace then
      if #filename > 0 then
        filename = string.sub( filename, 1, #filename - 1 )
      end
      return
    end
    if shift then 
      local k = MyShift[key]
      if k then key = k
      else
        key = key:upper()
      end
    end
    filename = filename .. key
    return
  end
  
  if key == sys.f2 then
    fsavemode = true
    if shift then falt = true end
    return
  end
  if fsavemode then
    if key == sys._return then
      fsavemode = false
      local ss
      if falt then
        ss = 'root =' .. Syntax.altdump( Syntax.tree.root ) .. ';'
      else
        ss = Syntax.dump( Syntax.tree.root )
      end
      local file = io.open(filename, "w+")
      if file == nil then
        message = "!!failure to saveful!!"
        return
      end      
      file:write( ss ); file:close()
      message = "**save successful**"
      falt = false
      return
    elseif key == sys.escape then 
      fsavemode, falt = false, false
      return
    elseif key == sys.backspace then
      if #filename > 0 then
        filename = string.sub( filename, 1, #filename - 1 )
      end
      return
    end
    if shift then 
      local k = MyShift[key]
      if k then key = k
      else
        key = key:upper()
      end
    end
    filename = filename .. key
    return
  end
    
  if key == sys.f3 then
    searchmode = true
    return
  end
  if searchmode then
    if key == sys._return then
      searchmode = false
      local node = Syntax.tree:search( Syntax.tree.root, searchstr )
      if node then
        Syntax.tree.select.selected = false
        Syntax.tree.select = node
        node.selected = true
        message = "**located**"
      else      
        message = "!!not found!!"
      end
      return
    elseif key == sys.escape then
      searchmode = false
      return
    elseif key == sys.backspace then
      if #searchstr > 0 then
        searchstr = string.sub( searchstr, 1, #searchstr - 1 )
      end
      return
    end
    if key == sys.space then key = ' ' end
    if shift then 
      local k = MyShift[key]
      if k then key = k
      else
        key = key:upper()
      end
    end
    searchstr = searchstr .. key

    return
  end
  
  if key == sys.f4 then
    if shift then
      if Keystroke.state == "pass" then
        Keystroke.cursor = Keystroke.altcursor
        Keystroke.state = "init"
        Syntax.mkRefTables( Syntax.tree.root, false )
      else
        Keystroke.state = "pass" 
        Keystroke.cursor = Keystroke.maincursor
      end
      return
    end
    local tmp = Syntax.reference
    Syntax.tree.state = Syntax.state
    Syntax.reference = Syntax.tree 
    Syntax.tree = tmp
    Syntax.state = tmp.state
    Syntax.refindex = {}
    
    Keystroke.tree = SynTree:new()
    Syntax.mkRefTables( Syntax.reference.root, true )
    
    showkeyparse = true
    return
  end
  
  if key == sys.f5 then
    Syntax.tree:sortLevel( Syntax.tree.select, not shift )
    return
  end
  
  if key == sys.f6 then 
    if shift then Syntax.tree:deleteRoot()
    else          Syntax.tree:insertRoot('Untitled')
    end  
    return
  end
  
  if key == sys.f8 and allegro then 
    io.write('out.mid:\n')

    local sortednotes = MidiLib.SortedNotesNew()
    ToMidi.setsortednotes( sortednotes )
    
    local start = Syntax.tree.root
    while start and start.name:sub(1,1) == '#' do start = start.child end
    
    ToMidi.evalAsRepeat( start, "initial" )
    
    local count = MidiLib.SortedNotesCount( sortednotes )
    local track = MidiLib.TrackNew( 6*count + 2 )
    MidiLib.SortedNotesTrackNotes( sortednotes, track )
    local tracklen = MidiLib.TrackLength( track ) 
    local midifile = MidiLib.MidiFileNew("out.mid", "w")
    MidiLib.MidiFileWriteChunk( midifile, track );
    MidiLib.SortedNotesDelete( sortednotes )
    MidiLib.TrackDelete( track )
    MidiLib.MidiFileDelete( midifile )

    io.write('tracklen = ' .. tracklen .. ' complete.\n')
    allegro.playmidi("out.mid"); 

    return
  end
    
  if key == sys.f9 then 
    if shift then showlist = not showlist
    end
    return
  end
    
  if key == sys.f10 then sys.quit() return end
  --
  -- at this point filter out some key events we don't want to record
  --
  if key == sys.insert or key == sys.delete then return end
  --
  -- fix up allegro punctuation keys
  --
  if allegro then key = Punctuation[key] or key end
    
  --
  -- deal with editmode and defmode ( define meaning )
  --

  if key == '\\' and not shift and not editmode and Syntax.tree.select then
    editmode = true
    Keystroke.input = Syntax.tree.select.name 
    return
  end
  if key == '\\' and not shift and editmode then 
    editmode = false
    Keystroke.input = ''
    return
    -- note: not the only place we leave editmode
  end
  
  message = nil
    
  if key == '[' and shift then 
    defmode = true
    if editmode and Syntax.tree.select.meaning then
      definition = Syntax.tree.select.meaning
    end
    return 
  end 
  
  if defmode then
    if key == ']' and shift then
      defmode = false
      if editmode then
        Syntax.tree.select.meaning = definition
        Keystroke.input, definition = '', ''
        editmode = false
      else        
        if #Keystroke.input == 0 and Syntax.tree.current then 
          Syntax.tree.current.meaning = definition
          definition = ''
        end
      end
      return
    end
    if key == sys._return or key == sys.space or key == sys.tab then key = ' '
    elseif key == sys.backspace then
      if #definition > 0 then
        definition = string.sub( definition, 1, #definition - 1 )
      end
      return
    end
    if shift then 
      local k = MyShift[key]
      if k then key = k
      else
        key = key:upper()
      end
    end
    definition = definition .. key
    return
  end
  
  --
  -- now we call one of the state machines
  --
  
  if key == sys.backspace then
    if #Keystroke.input > 0 then
      Keystroke.current = Keystroke.nextState( key, Keystroke.current )
      return
    end
    if shift then Syntax.tree.current = Syntax.nextState( key, Syntax.tree.current ) end
    return
  end

  if key == sys.tab or key == sys._return then
    
    if Keystroke.state ~= "pass" and Keystroke.state ~= "init" and 
        Keystroke.state ~= "valid" and Keystroke.state ~= "term" and
        Keystroke.state ~= "hyper" then
      return
    end
    
    if key == sys.tab then key = '\t'
    else key = '\n' end
  
    if #Keystroke.input > 0 then 
      if editmode then
        Syntax.tree.select.name = Keystroke.input
        editmode = false
        Keystroke.input = ""
        return
      elseif Keystroke.state == "hyper" then
        Syntax.tree.current = Syntax.nextState( Keystroke.hyper[Keystroke.hindex], Syntax.tree.current )
      else
        Syntax.tree.current = Syntax.nextState( Keystroke.input, Syntax.tree.current )
        if #definition > 0 then 
          Syntax.tree.current.meaning = definition 
          definition = ""
        end
      end
      Keystroke.current = Keystroke.nextState( key, Keystroke.current )
    end
    Syntax.tree.current = Syntax.nextState( key, Syntax.tree.current )
    return
  end
  
  if key == sys.space then key = ' '
  elseif shift then
    local k = MyShift[key]
    if k then key = k
    else      key = key:upper() end    
  end
  
  Keystroke.current = Keystroke.nextState( key, Keystroke.current )
  
end
  
---------------------------------------------------------------------
-- mouse event handlers
---------------------------------------------------------------------

function sys.mousepressed( x, y, button )
  
  if button ~= 1 then return end
  
  if Syntax.tree:locate( Syntax.tree.root, x, y ) then return end
  
  mousehold = true
  return
end

function sys.mousemoved( x, y, dx, dy )
  
  if not mousehold then return end
    
  scrollX = scrollX + dx
  scrollY = scrollY + dy  
  return
end
  
function sys.mousereleased( x, y, button )
  
  if button ~= 1 then return end
  
  mousehold = false
  
  local node = Syntax.tree:locate( Syntax.tree.root, x, y )
  if node then
    if shift then
      Syntax.tree.current = node
    else      
      Syntax.tree.select.selected = false
      Syntax.tree.select = node
      node.selected = true
    end
  end
  
end

---------------------------------------------------------------------
-- load and update handlers
---------------------------------------------------------------------

function sys.load( arg )
  
  fontsize = 12
  screenX, screenY  = 800, 600
  if arg then
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    local argn
    for argn = 2, #arg do
      local a = arg[argn]
      if a == "-fontsize" then
        argn = argn + 1
        fontsize = tonumber( arg[argn] )
      elseif a == "-width" then
        argn = argn + 1
        screenX = tonumber( arg[argn] )
      elseif a == "-height" then
        argn = argn + 1
        screenY = tonumber( arg[argn] )        
      end
    end
  end
  
  if love then
    love.window.setMode( screenX, screenY )
    screenX, screenY  = love.graphics.getDimensions()
    love.window.setTitle( "(Tiny) Tree Editor" )
    font = love.graphics.setNewFont( fontsize )
  end
  if allegro then
    allegro.setMode( screenX, screenY )
    allegro.setTitle( "(Tiny) Tree Editor" )
    MidiLib = require("libluamidi")
    ToMidi = require("tomidi")
    ToMidi.setmidilib( MidiLib )
  end
  
  fontheight = sys.fontheight()
  
  Keystroke.init()
  
  treeYbegin = 16 + 4*fontheight
  
end

function sys.update()
  
  if showkeyparse and Keystroke.tree and Keystroke.tree.current then
    Keystroke.tree:setRowPosition( 8 + scrollX, treeYbegin + scrollY, Keystroke.tree.root, sys.getwidth)
    return
  end
    
  if Syntax.tree.root then
    if showlist then
      Syntax.tree:setListPosition( 8 + scrollX, treeYbegin + scrollY, Syntax.tree.root, 1 )
    else
      Syntax.tree:setRowPosition( 8 + scrollX, treeYbegin + scrollY, Syntax.tree.root, sys.getwidth )
    end
    
    if autoscroll and Syntax.tree.current then
      if Syntax.tree.current.x < 0 then scrollX = scrollX + screenX*0.1
      elseif Syntax.tree.current.x > screenX*0.8 then scrollX = scrollX - screenX*0.2
      end
      if Syntax.tree.current.y < treeYbegin then scrollY = scrollY + screenY*0.1
      elseif Syntax.tree.current.y > screenY*0.8 then scrollY = scrollY - screenY*0.2
      end
    end
  end
  
  Keystroke.cursor:update()
  
end

---------------------------------------------------------------------
-- drawing event handlers
---------------------------------------------------------------------

function sys.draw()  
  
  sys.graphics.setColor( 25, 25, 25 )
  sys.graphics.rectangle( "fill", 0, 0, screenX, screenY )
  
  sys.graphics.setColor( 100, 50, 0, 255 )
  sys.graphics.rectangle( "fill", 0, 0, screenX, fontheight + 4 )
  
  sys.graphics.setColor( 0, 100, 50, 255 )
  sys.graphics.rectangle( "fill", 0, fontheight + 4, screenX, fontheight + 4  )
  
  Keystroke.cursor.x = 8 + sys.getwidth( Keystroke.input )
  
  sys.graphics.setColor( Keystroke.cursor.r, Keystroke.cursor.g, Keystroke.cursor.b, 255 )
  sys.graphics.rectangle("fill", Keystroke.cursor.x, Keystroke.cursor.y, Keystroke.cursor.width, Keystroke.cursor.height )
  
  sys.graphics.setColor( 255, 255, 255, 255 )
  sys.graphics.setBackgroundColor( 100, 50, 0, 255 )
  
  if searchmode then
    sys.graphics.print( "Search for Node: " .. searchstr, 2, 2 )
  elseif floadmode then
    sys.graphics.print( "File to Load: " .. filename, 2, 2 )
  elseif fsavemode then
    sys.graphics.print( "File to Save: " .. filename, 2, 2 )
  elseif shift then
    sys.graphics.print( "Use Arrow/Home/End to navigate for editing. Insert/Delete to cut&paste, `\\' to edit.", 2, 2) 
    sys.graphics.setBackgroundColor( 0, 100, 50, 255 )
    sys.graphics.print( "F1 Alt-Load/F2 Alt-Save/F3/F4 Restrictive Mode/F5 Reverse Sort/F6 Delete Root/../F9 List View/F10", 2, 6 + fontheight ) 
  elseif message then
    sys.graphics.print( message, 2, 2 )
  else
    sys.graphics.print( "Enter SOMETHING then `enter' to descend, `tab' to remain at that level. `{' your_meaning `}' to add meaning. Shift=more help", 2, 2)
    sys.graphics.setBackgroundColor( 0, 100, 50, 255 )
    sys.graphics.print( "F1 Load/F2 Save/F3 Search/F4 Reference Swap/F5 Sort/F6 Insert Root/../F8 Gen Midi/F9 Help/F10 Exit", 2, 6 + fontheight ) 
  end

  sys.graphics.setBackgroundColor(0, 0, 0, 255 )

  if #Keystroke.input > 0 then
    if Keystroke.state == "valid" or Keystroke.state == "term" then
      sys.graphics.setColor( 0, 255, 0, 255 )
      sys.graphics.print( Keystroke.input, 8, 14 + 3*fontheight )
      sys.graphics.setColor( 255, 255, 255, 255 )
    elseif Keystroke.state == "hyper" then
      sys.graphics.print( Keystroke.hyper[Keystroke.hindex], 8, 14 + 3*fontheight )
    else
      sys.graphics.print( Keystroke.input, 8, 14 + 3*fontheight )
    end
  end
  if Keystroke.hyper then
    local n = Syntax.refindex[Keystroke.hyper[Keystroke.hindex]]
    if n then sys.graphics.print( '{'.. n.meaning .. '}', 8, 10 + 2 * fontheight ) end
  elseif defmode then
    sys.graphics.print('{' .. definition, 8, 10 + 2 * fontheight )
  end

  if showkeyparse and Keystroke.tree and Keystroke.tree.current then
    Keystroke.tree:display(Keystroke.tree.root, true, sys.graphics, sys.getwidth)
    return
  end
  
  if Syntax.tree.current then
    
    Syntax.tree:display( Syntax.tree.root, not showlist, sys.graphics, sys.getwidth )
  
    if Syntax.state == "desc" then
      sys.graphics.circle("fill", Syntax.tree.current.x + Syntax.tree.current.xlen/2, Syntax.tree.current.y + 1.5*fontheight, fontheight/2 )
    elseif Syntax.state == "wait" then
      sys.graphics.circle("fill", Syntax.tree.current.x + Syntax.tree.current.xlen + fontheight/2, Syntax.tree.current.y + fontheight/2, fontheight/2 )
    end
    
  else
    sys.graphics.circle("fill", 16, 22 + 4 * fontheight, fontheight/2 )    
  end
  
end

if love then
  love.load = sys.load
  love.update = sys.update
  love.draw = sys.draw
  love.mousepressed = sys.mousepressed
  love.mousereleased = sys.mousereleased
  love.mousemoved = sys.mousepressed
  love.keypressed = sys.keypressed
  love.keyreleased = sys.keyreleased
end
if allegro then
  allegro.load = sys.load
  allegro.update = sys.update
  allegro.draw = sys.draw
  allegro.mousepressed = sys.mousepressed
  allegro.mousereleased = sys.mousereleased
  allegro.mousemoved = sys.mousepressed
  allegro.keypressed = sys.keypressed
  allegro.keyreleased = sys.keyreleased
end
