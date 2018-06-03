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

trees = { Syntax.tree }
scrollX, scrollY, pagenum = 0, 0, 0
definition, filename, searchstr, message = "", "", "", nil
shift, defmode, editmode, autoscroll = false, false, false, true
floadmode, fsavemode, falt, searchmode = false, false, false, false
mousehold, mouseTreehold = false, false 
showkeyparse, showlist = false, false
capturemode, metro = false, false

if love then
  sys = require "lovedef"
elseif sdl then
  sys = require "sdldef"
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
    
    Syntax.tree:setTreePosition( 10 + scrollX, treeYbegin + scrollY, Syntax.tree.root, sys.getwidth )
  end
end

---------------------------------------------------------------------
-- midi event handlers
---------------------------------------------------------------------

function sys.noteon( channel, pitch, velocity, time )
  
  if capturemode then
    converter.noteon( channel, pitch, velocity, time)
  end
  alsa.sendnoteon( channel, pitch, velocity, time )
  alsa.drain()
  
end

function sys.noteoff( channel, pitch, velocity, time )
  
  if capturemode then
    converter.noteoff( channel, pitch, velocity, time)
  else
    Keystroke.input = converter.pitch2note( pitch ) or Keystroke.input
  end
  alsa.sendnoteoff( channel, pitch, velocity, time )
  alsa.drain()
  
end

---------------------------------------------------------------------
-- mouse event handlers
---------------------------------------------------------------------

function sys.mousepressed( x, y, button )
  
  if button ~= 1 then return end
  
  if Syntax.tree:locate( Syntax.tree.root, x, y ) then 
    mouseTreehold = true
    holdtree = Syntax.tree
    return
  end
  
  mousehold = true
  return
end

function sys.mousemoved( x, y, dx, dy )
  
  local breaknode, newtree
  if mousehold then 
    scrollX = scrollX + dx
    scrollY = scrollY + dy  
  elseif mouseTreehold then
    if shift then
      breaknode = holdtree:locate( holdtree.root, x, y )
      newtree = holdtree:split( breaknode )
      newtree.select = newtree.root 
      newtree.select.selected = true
      newtree.current = newtree:outerChild( newtree.root )
      newtree.cutbuffer = Syntax.tree.cutbuffer
      Syntax.tree.select.selected = false
      trees[#trees+1], Syntax.tree, holdtree = newtree, newtree, newtree
      shift = false      -- necessary or we will keep coming back here
    else
      holdtree.xoffs = holdtree.xoffs + dx
      holdtree.yoffs = holdtree.yoffs + dy
    end
  end    
  return
end
  
function sys.mousereleased( x, y, button )
  
  local node
  if button == 2 then
    node = Syntax.tree:locate( Syntax.tree.root, x, y )
    if node then node.open = not node.open end
    return
  end
  
  if button ~= 1 then return end
  
  mousehold, mouseTreehold = false, false
  
  local k, v
  node = Syntax.tree:locate( Syntax.tree.root, x, y )
  if node then
    if shift then
      Syntax.tree.current = node
    else
      if node.selected then
        editmode = true
        Keystroke.input = node.name 
      else      
        Syntax.tree.select.selected = false
        Syntax.tree.select = node
        node.selected = true
      end
    end
  else
    for k, v in ipairs( trees ) do
      node = v:locate( v.root, x, y )
      if node then
        v.cutbuffer = Syntax.tree.cutbuffer
        Syntax.tree.select.selected = false
        Syntax.tree = v
        if shift then
          Syntax.tree.current = node
        else      
          Syntax.tree.select.selected = false
          Syntax.tree.select = node
          node.selected = true
        end
        break
      end
    end
  end
  
end

---------------------------------------------------------------------
-- key event handlers
---------------------------------------------------------------------

function sys.keypressed( key )
  if key == sys.leftshift or key == sys.rightshift then
    if alsa then
      converter.first()
      if shift then alsa.clear() end
    end
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
    if ((key == sys.down and not showlist) or (key == sys.right and showlist)) 
          and p and p.child and p.open then
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
  
  if key == sys.pageup then
    if mouseTreehold then
      holdtree.page = pagenum + 1
    end
    pagenum = pagenum + 1
    return
  end
  
  if key == sys.pagedown then 
    if mouseTreehold then
      holdtree.page = pagenum - 1
    end
    pagenum = pagenum - 1
    return
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
    Syntax.tree:sortLevel( Syntax.tree.select, not shift )
    return
  end
  
  if key == sys.f5 then
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
  
  if key == sys.f6 then 
    if shift then Syntax.tree:deleteRoot()
    else          Syntax.tree:insertRoot('Untitled')
    end  
    return
  end
  
  if key == sys.f7 and alsa then
    if shift then 
      capturemode = not capturemode
      if capturemode then converter.first() end
    else 
      metro = not metro
      alsa.metronome( metro )
    end
    return
  end
  
  if key == sys.f8 and alsa then 
    alsa.stop()
    alsa.drain()
    local tick, events = alsa.tick()
    local rem = tick % 96
    tick = tick + 96 - rem
    io.write("start tick="..tick.."\n")
    converter.reset( tick )
    alsa.continue();    
    local start
    if shift then
      start = Syntax.tree.select
      converter.evalAsList( start, "initial" )
    else
      start = Syntax.tree.root
      while start and start.name:sub(1,1) == '#' do start = start.child end
      converter.evalAsList( start, "initial" )
    end
    alsa.drain()
    
    return
  end
    
  if key == sys.f9 then 
    if shift then showlist = not showlist
    end
    return
  end
    
  if key == sys.f10 then 
    if alsa then 
      alsa.queueoff()
      alsa.close()
    end
    sys.quit()
    return
  end
  --
  -- at this point filter out some key events we don't want to record
  --
  if key == sys.insert or key == sys.delete then return end
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
  -- look for tree merge request
  --
  
  if shift then
    if key == sys._return or key == sys.tab then
      local dest, x, y, k, v
      x = Syntax.tree.root.x - Syntax.tree.xoffs
      y = Syntax.tree.root.y - Syntax.tree.yoffs
      for k, v in ipairs( trees ) do
        if v ~= Syntax.tree then
          dest = v:locate( v.root, x, y )
          if dest then
            if key == sys._return then v:merge( dest, "child", Syntax.tree ) end
            if key == sys.tab then v:merge( dest, "sibling", Syntax.tree ) end
            
          end 
        end
      end
    end
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
-- load and update handlers
---------------------------------------------------------------------

function sys.load( arg )
  
  fontsize = 12
  screenX, screenY  = 800, 600
 
  if arg then
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    local argn = 2
    while argn <= #arg do
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
      argn = argn+1
    end
  end
  
  converter = require("convertmidi")
  alsa = require("libluaalsa")
  
  if love then
    love.window.setMode( screenX, screenY )
    screenX, screenY  = love.graphics.getDimensions()
    love.window.setTitle( "(Tiny) Tree Editor" )
    font = love.graphics.setNewFont( fontsize )
  end
  if sdl then
    sdl.setMode( screenX, screenY )
    sdl.setTitle( "(Tiny) Tree Editor" )
    local f = sdl.newFont("8x14.bmp", 8, 14, 0, 0, 0, 0, 0, 16, 256 )
    sdl.setFont( f ) 
  end
  if alsa then
    alsa.noteon = sys.noteon
    alsa.noteoff = sys.noteoff
    alsa.init()
    alsa.queueon()
    alsa.start()
    alsa.drain()
  end
  
  fontheight = sys.fontheight()
  
  Keystroke.init()
  
  treeYbegin = 16 + 4*fontheight
  
end

function sys.update()
  
  if alsa then alsa.update() end
  
  if showkeyparse and Keystroke.tree and Keystroke.tree.current then
    Keystroke.tree:setTreePosition( 8 + scrollX, treeYbegin + scrollY, Keystroke.tree.root, sys.getwidth)
    return
  end
    
  for k, v in ipairs( trees ) do
    if v.current and v.page == pagenum then       
      if showlist then
        v:setListPosition( 8 + scrollX, treeYbegin + scrollY, v.root, 1, sys.getwidth )
      else
        v:setTreePosition( 8 + scrollX, treeYbegin + scrollY, v.root, sys.getwidth )
      end
    end
  end
      
  if autoscroll and Syntax.tree.current and Syntax.tree.current.x then
    if Syntax.tree.current.x < 0 then scrollX = scrollX + screenX*0.1
    elseif Syntax.tree.current.x > screenX*0.8 then scrollX = scrollX - screenX*0.2
    end
    if Syntax.tree.current.y < treeYbegin then scrollY = scrollY + screenY*0.1
    elseif Syntax.tree.current.y > screenY*0.8 then scrollY = scrollY - screenY*0.2
    end
  end
  
  Keystroke.cursor:update()
  
end

---------------------------------------------------------------------
-- drawing event handlers
---------------------------------------------------------------------

function sys.draw()  
  
  sys.graphics.setColor( 0.1, 0.1, 0.1, 1 )
  sys.graphics.rectangle( "fill", 0, 0, screenX, screenY )
  
  sys.graphics.setColor( 0.4, 0.2, 0, 1 )
  sys.graphics.rectangle( "fill", 0, 0, screenX, fontheight + 4 )
  
  sys.graphics.setColor( 0, 0.4, 0.2, 1 )
  sys.graphics.rectangle( "fill", 0, fontheight + 4, screenX, fontheight + 4  )
  
  Keystroke.cursor.x = 8 + sys.getwidth( Keystroke.input )
  
  sys.graphics.setColor( Keystroke.cursor.r, Keystroke.cursor.g, Keystroke.cursor.b, 255 )
  sys.graphics.rectangle("fill", Keystroke.cursor.x, Keystroke.cursor.y, Keystroke.cursor.width, Keystroke.cursor.height )
  
  sys.graphics.setColor( 1, 1, 1, 1 )
  sys.graphics.setBackgroundColor( 0.4, 0.2, 0, 1 )
  
  if searchmode then
    sys.graphics.print( "Search for Node: " .. searchstr, 2, 2 )
  elseif floadmode then
    sys.graphics.print( "File to Load: " .. filename, 2, 2 )
  elseif fsavemode then
    sys.graphics.print( "File to Save: " .. filename, 2, 2 )
  elseif shift then
    sys.graphics.print( "Use Arrow/Home/End to navigate for editing. Insert/Delete to cut&paste, `\\' to edit.", 2, 2) 
    sys.graphics.setBackgroundColor( 0, 0.4, 0.2, 1 )
    sys.graphics.print( "F1 Alt-Load/F2 Alt-Save/F3/F4 Reverse Sort/F5 Restrictive Mode/F6 Delete Root/F7 Capture/F8 Gen Select/F9 List View/F10", 2, 6 + fontheight ) 
  elseif message then
    sys.graphics.print( message, 2, 2 )
  else
    sys.graphics.print( "Enter SOMETHING then `enter' to descend, `tab' to remain at that level. `{' your_meaning `}' to add meaning. Shift=more help", 2, 2)
    sys.graphics.setBackgroundColor( 0, 0.4, 0.2, 1 )
    sys.graphics.print( "F1 Load/F2 Save/F3 Search/F4 Sort/F5 Reference Swap/F6 Insert Root/F7 Metro/F8 Gen Midi/F9 Help/F10 Exit", 2, 6 + fontheight ) 
  end

  sys.graphics.setBackgroundColor(0, 0, 0, 1 )

  if #Keystroke.input > 0 then
    if Keystroke.state == "valid" or Keystroke.state == "term" then
      sys.graphics.setColor( 0, 1, 0, 1 )
      sys.graphics.print( Keystroke.input, 8, 14 + 3*fontheight )
      sys.graphics.setColor( 1, 1, 1, 1 )
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
  
  local k, v
  for k, v in ipairs( trees ) do
    if v.current and v.page == pagenum then 
      v:display( v.root, not showlist, sys.graphics, sys.getwidth )
    end
  end
  
  if Syntax.tree.current and Syntax.tree.current.xlen == nil then return end
  
  if Syntax.tree.current and Syntax.tree.page == pagenum then
    
    if Syntax.state == "desc" then
      sys.graphics.circle("fill", Syntax.tree.current.x + Syntax.tree.current.xlen/2, Syntax.tree.current.y + 1.5*fontheight, fontheight/2 )
    elseif Syntax.state == "wait" then
      sys.graphics.circle("fill", Syntax.tree.current.x + Syntax.tree.current.xlen + fontheight/2, Syntax.tree.current.y + fontheight/2, fontheight/2 )
    end
    
  elseif pagenum == 0 then
    sys.graphics.circle("fill", 16, 22 + 4 * fontheight, fontheight/2 )    
  end
  
end

if love then
  love.load = sys.load
  love.update = sys.update
  love.draw = sys.draw
  love.mousepressed = sys.mousepressed
  love.mousereleased = sys.mousereleased
  love.mousemoved = sys.mousemoved
  love.keypressed = sys.keypressed
  love.keyreleased = sys.keyreleased
elseif sdl then
  sdl.load = sys.load
  sdl.update = sys.update
  sdl.draw = sys.draw
  sdl.mousepressed = sys.mousepressed
  sdl.mousereleased = sys.mousereleased
  sdl.mousemoved = sys.mousemoved
  sdl.keypressed = sys.keypressed
  sdl.keyreleased = sys.keyreleased  
end
