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

function adjustSelectScroll()
  
  while Syntax.tree.select.x > screenX*0.8 or Syntax.tree.select.x < 8 or
      Syntax.tree.select.y > screenY*0.8 or Syntax.tree.select.y < treeYbegin do
    
    autoscroll = false
    
    if Syntax.tree.select.x > screenX*0.8 then
      scrollX = scrollX - screenX*0.2 
    elseif Syntax.tree.select.x < 10 then
     scrollX = scrollX + screenX*0.2
    end
    if Syntax.tree.select.y > screenY*0.8 then
      scrollY = scrollY - screenY*0.2 
    elseif Syntax.tree.select.y < treeYbegin then
      scrollY = scrollY + screenY*0.2
    end
    
    Syntax.tree.xhi, Syntax.tree.yhi = 0, 0
    Syntax.tree:setRowPosition( 10 + scrollX, treeYbegin + scrollY, Syntax.tree.root, 1 )
  end
end

---------------------------------------------------------------------
-- key event handlers
---------------------------------------------------------------------

function love.keypressed( key )
  if key == 'lshift' or key == 'rshift' then
    shift = true
  end
  if blurb > 0 then 
    if key == 'escape' then blurb = 0
    else blurb = blurb - 1
    end  
  end
  showkeyparse = false
end

function love.keyreleased( key ) 
  local p = Syntax.tree.select
    
  if blurb > 0 then return 
  elseif blurb == 0 then
    blurb = -1
    return
  end
  
  if key == 'lshift' or key == 'rshift' then
    shift = false
    return
  end
  
  if Keystroke.state == "pass" then  
    if key == 'home' and p then
      p.selected = false
      Syntax.tree.select = Syntax.tree.root
      Syntax.tree.select.selected = true
      adjustSelectScroll()
      return
    end
    if key == 'end' then
      autoscroll = true
      return
    end
    if key == 'down' and p and p.child then
      p.selected = false
      p = p.child
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
    if key == 'up' and p and p.parent then
      p.selected = false
      p = p.parent
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
    if key == 'left' and p and p.prev then
      p.selected = false
      p = p.prev
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
    if key == 'right' and p and p.next then
      p.selected = false
      p = p.next
      p.selected = true
      Syntax.tree.select = p
      adjustSelectScroll()
      return
    end
  end
  
  if key == 'delete' and Syntax.tree.select then
    local newselect = Syntax.tree.select.parent
    if newselect == nil then return end
    
    Syntax.tree.select.selected = false
    Syntax.tree:cut( Syntax.tree.select )
    Syntax.tree.select = newselect
    newselect.selected = true
    return
  end
  if key == 'insert' and Syntax.tree.cutbuffer then
    Syntax.tree:paste( Syntax.tree.select )
    return
  end
  
  if key == 'f1' then
    floadmode = true
    if shift then falt = true end
    return
  end
  if floadmode then
    if key == 'return' then
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
    elseif key == 'escape' then
      floadmode, falt = false, false
      return
    elseif key == 'backspace' then
      if #filename > 0 then
        filename = string.sub( filename, 1, #filename - 1 )
      end
      return
    end
    if shift then key = key:upper() end
    filename = filename .. key
    return
  end
  
  if key == 'f2' then
    fsavemode = true
    if shift then falt = true end
    return
  end
  if fsavemode then
    if key == 'return' then
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
    elseif key == 'escape' then 
      fsavemode, falt = false, false
      return
    elseif key == 'backspace' then
      if #filename > 0 then
        filename = string.sub( filename, 1, #filename - 1 )
      end
      return
    end
    if shift then key = key:upper() end
    filename = filename .. key
    return
  end
    
  if key == 'f3' then
    searchmode = true
    return
  end
  if searchmode then
    if key == 'return' then
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
    elseif key == 'escape' then
      searchmode = false
      return
    elseif key == 'backspace' then
      if #searchstr > 0 then
        searchstr = string.sub( searchstr, 1, #searchstr - 1 )
      end
      return
    end
    if key == 'space' then key = ' '
    elseif shift then key = key:upper()
    end
    searchstr = searchstr .. key

    return
  end
  
  if key == 'f4' then
    if shift then
      if Keystroke.state == "pass" then
        Keystroke.cursor = Keystroke.altcursor
        Keystroke.state = "init"
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
    
    Syntax.mkRefTables( Syntax.reference.root )
    showkeyparse = true
    return
  end
  
  if key == 'f5' then
    Syntax.tree:sortLevel( Syntax.tree.select, not shift )
    return
  end
  
  if key == 'f6' then 
    if shift then Syntax.tree:deleteRoot()
    else          Syntax.tree:insertRoot('Untitled')
    end  
    return
  end
  
  if key == 'f10' then love.event.quit() return end
  --
  -- at this point filter out some key events we don't want to record
  --
  if key == 'insert' or key == 'delete' then return end
    
  if key == '\\' and not editmode and Syntax.tree.select then
    editmode = true;
    Keystroke.input = Syntax.tree.select.name 
    return
  end
  if key == '\\' and editmode then 
    editmode = false
    Keystroke.input = ''
    return
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
        Keystroke.input = ''
        editmode = false
      else        
        if Syntax.tree.current then 
          Syntax.tree.current.meaning = definition
        end
      end
      definition = ""
      return
    end
    if key == 'return' or key == 'space' or key == 'tab' then key = ' '
    elseif key == 'backspace' then
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
  autoscroll = true
  
  if key == 'backspace' then
    if #Keystroke.input > 0 then
      Keystroke.current = Keystroke.nextState( key, Keystroke.current )
      return
    end
    Syntax.tree.current = Syntax.nextState( key, Syntax.tree.current )
    return
  end

  if key == 'tab' or key == 'return' then
    
    if Keystroke.state ~= "pass" and Keystroke.state ~= "valid" and 
       Keystroke.state ~= "term" and Keystroke.state ~= "hyper" then
      return
    end
    
    if key == 'tab' then key = '\t'
    else key = '\n' end
  
    if #Keystroke.input > 0 then 
      if editmode then
        Syntax.tree.select.name = Keystroke.input
        editmode = false
        return
      elseif Keystroke.state == "hyper" then
        Syntax.tree.current = Syntax.nextState( Keystroke.hyper[Keystroke.hindex], Syntax.tree.current )
      else
        Syntax.tree.current = Syntax.nextState( Keystroke.input, Syntax.tree.current )
      end
      Keystroke.current = Keystroke.nextState( key, Keystroke.current )
    end
    Syntax.tree.current = Syntax.nextState( key, Syntax.tree.current )
    return
  end
  
  if key == 'space' then key = ' '
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

function love.mousepressed( x, y, button )
  
  if button ~= 1 then return end
  
  local node = Syntax.tree:locate( Syntax.tree.root, x, y )
  if node then return end
  
  mousehold = true
  return
end

function love.mousemoved( x, y, dx, dy )
  
  if not mousehold then return end
    
  scrollX = scrollX + dx
  scrollY = scrollY + dy  
  return
end
  
function love.mousereleased( x, y, button )
  
  if button ~= 1 then return end
  
  mousehold = false
  
  local node = Syntax.tree:locate( Syntax.tree.root, x, y )
  if node then
    Syntax.tree.select.selected = false
    Syntax.tree.select = node
    node.selected = true
  end
  
end

---------------------------------------------------------------------
-- load and update handlers
---------------------------------------------------------------------

function love.load( arg )
  
  fontsize = 12
  if arg then
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    local argn
    for argn = 2, #arg do
      local a = arg[argn]
      if a == "-fontsize" then
        argn = argn + 1
        fontsize = tonumber( arg[argn] )
      end
    end
  end
  
  screenX, screenY  = love.graphics.getDimensions()
  love.window.setTitle( "(Tiny) Tree Editor" )
  
  font = love.graphics.setNewFont( fontsize )
  fontheight = font:getHeight()
  
  Keystroke.init()
  love.keyboard.setTextInput( true )
  
  treeYbegin = 16 + 4*fontheight
  
  if love.filesystem.exists("Blurb1.png") and love.filesystem.exists("Blurb2.png") and 
     love.filesystem.exists("Blurb3.png") then
    blurb1pix = love.graphics.newImage( "Blurb1.png" )
    blurb2pix = love.graphics.newImage( "Blurb2.png" )
    blurb3pix = love.graphics.newImage( "Blurb3.png" )
    blurb = 3
  else
    blurb = 0
  end
end

function love.update()
  
  if showkeyparse and Keystroke.tree and Keystroke.tree.current then
    Keystroke.tree.xhi, Keystroke.tree.yhi = 0, 0
    Keystroke.tree:setRowPosition( 8 + scrollX, treeYbegin + scrollY, Keystroke.tree.root, 1)
    return
  end
    
  if Syntax.tree.root then
    Syntax.tree.xhi, Syntax.tree.yhi = 0, 0
    Syntax.tree:setRowPosition( 8 + scrollX, treeYbegin + scrollY, Syntax.tree.root, 1 )
    
    if autoscroll then
      if Syntax.tree.xhi > screenX*0.8 then scrollX = scrollX - screenX*0.2 end
      if Syntax.tree.yhi > screenY*0.8 then scrollY = scrollY - screenY*0.2 end
    end
  end
  
  Keystroke.cursor:update()
  
end

---------------------------------------------------------------------
-- drawing event handlers
---------------------------------------------------------------------

function love.draw()  
  
  if blurb > 0 then
    if blurb == 3 then
      love.graphics.draw( blurb1pix, 0, 0 )
    elseif blurb == 2 then
      love.graphics.draw( blurb2pix, 0, 0 )
    elseif blurb == 1 then
      love.graphics.draw( blurb3pix, 0, 0 )
    end
    return
  end

  love.graphics.setColor( 25, 25, 25 )
  love.graphics.rectangle( "fill", 0, 0, screenX, screenY )
  
  love.graphics.setColor( 100, 50, 0, 255 )
  love.graphics.rectangle( "fill", 0, 0, screenX, fontheight + 4 )
  
  love.graphics.setColor( 0, 100, 50, 255 )
  love.graphics.rectangle( "fill", 0, fontheight + 4, screenX, fontheight + 4  )
  
  Keystroke.cursor.x = 8 + font:getWidth( Keystroke.input )
  
  love.graphics.setColor( Keystroke.cursor.r, Keystroke.cursor.g, Keystroke.cursor.b, 255 )
  love.graphics.rectangle("fill", Keystroke.cursor.x, Keystroke.cursor.y, Keystroke.cursor.width, Keystroke.cursor.height )
  
  love.graphics.setColor( 255, 255, 255, 255 )
  
  if searchmode then
    love.graphics.print( "Search for Node: " .. searchstr, 2, 2 )
  elseif floadmode then
    love.graphics.print( "File to Load: " .. filename, 2, 2 )
  elseif fsavemode then
    love.graphics.print( "File to Save: " .. filename, 2, 2 )
  elseif shift then
    love.graphics.print( "Use Arrow/Home/End to navigate for editing. Insert/Delete to cut&paste, `\\' to edit.", 2, 2) 
    love.graphics.print( "F1 Load/F2 Save/F3 Search/F4 Reference Swap/F5 Sort/F6 Root/../F10 Exit", 2, 6 + fontheight ) 
  elseif message then
    love.graphics.print( message, 2, 2 )
  else
    love.graphics.print( "Enter WORDS `enter' to descend and `tab' to remain at that level. Use `{' your_meaning `}' to add meaning. Shift=more help", 2, 2) 
  end

  if #Keystroke.input > 0 then
    if Keystroke.state == "valid" or Keystroke.state == "term" then
      love.graphics.setColor( 0, 255, 0, 255 )
      love.graphics.print( Keystroke.input, 8, 14 + 3*fontheight )
      love.graphics.setColor( 255, 255, 255, 255 )
    elseif Keystroke.state == "hyper" then
      love.graphics.print( Keystroke.hyper[Keystroke.hindex], 8, 14 + 3*fontheight )
    else
      love.graphics.print( Keystroke.input, 8, 14 + 3*fontheight )
    end
  end
  if Keystroke.hyper then
    local n = Syntax.refindex[Keystroke.hyper[Keystroke.hindex]]
    if n then love.graphics.print( '{'.. n.meaning .. '}', 8, 10 + 2 * fontheight ) end
  elseif defmode then
    love.graphics.print('{' .. definition, 8, 10 + 2 * fontheight )
  end

  if showkeyparse and Keystroke.tree and Keystroke.tree.current then
    Keystroke.tree:display(Keystroke.tree.root)
    return
    
  elseif Syntax.tree.current then
    if not shift then
      if editmode then
        if Syntax.tree.select.meaning then
          love.graphics.print('SELECT="' .. Syntax.tree.select.name .. '" {' .. Syntax.tree.select.meaning .. '} depth=' .. Syntax.tree.select.depth, 2, 6 + fontheight )    
        else
          love.graphics.print('SELECT="' .. Syntax.tree.select.name .. '" depth=' .. Syntax.tree.select.depth, 2, 6 + fontheight )
        end
      else
        if Syntax.tree.current.meaning then
          love.graphics.print('CURRENT="' .. Syntax.tree.current.name .. '" {' .. Syntax.tree.current.meaning .. '} state=' .. Syntax.state .. ' depth=' .. Syntax.depth, 2, 6 + fontheight )
        else
          love.graphics.print('CURRENT="' .. Syntax.tree.current.name .. '" state=' .. Syntax.state .. ' depth=' .. Syntax.depth, 2, 6 + fontheight )
        end        
      end
    end
    
    Syntax.tree:display( Syntax.tree.root )
  
    if Syntax.state == "desc" then
      love.graphics.circle("fill", Syntax.tree.current.x + Syntax.tree.current.xlen/2, Syntax.tree.current.y + 1.5*fontheight, fontheight/2 )
    elseif Syntax.state == "wait" then
      love.graphics.circle("fill", Syntax.tree.current.x + Syntax.tree.current.xlen + fontheight/2, Syntax.tree.current.y + fontheight/2, fontheight/2 )
    end
    
  else
    love.graphics.circle("fill", 16, 22 + 4 * fontheight, fontheight/2 )    
  end
  
end
