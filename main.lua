-------------------------------------------------------------
--    (Tiny) Tree Editor
--    Author: John Derry (johndderry@yahoo.com)
--    Version: 1.0
--    No Rights Reserved
-------------------------------------------------------------

-------------------------------------------------------------
--  SynNode class 
-------------------------------------------------------------

SynNode = {}

function SynNode:new(parent)
  o = {}
  setmetatable(o, self)
  self.__index = self  
  o.next, o.prev, o.child = nil, nil, nil
  o.parent = parent
  o.name = "Node"
  o.selected = false
  return o
end

-------------------------------------------------------------
--  SynTree class
-------------------------------------------------------------

SynTree = {}

function SynTree:new()
  o = {}
  setmetatable(o, self)
  self.__index = self
  self.root, self.current, self.select = nil, nil, nil
  self.state = "init"
  return o
end

function SynTree:attach( parent, atpoint, name )
  local node = SynNode:new( parent )
  node.name = name
  node.depth = smachine.depth
  if parent == nil and atpoint == nil then
    node.selected = true
    self.root, self.select = node, node
  else
    node.next = atpoint.next
    if atpoint.next then 
      atpoint.next.prev = node
    end
    
    atpoint.next = node
    node.prev = atpoint
  end
  return node  
end
  
function SynTree:attachChild( parent, name )
  if parent == nil then return nil end
  
  local node = SynNode:new( parent )
  node.name = name
  node.depth = smachine.depth
  node.next = parent.child
  parent.child = node 
  
  return node
end

function inTree( node, test )
  if node.child then 
    if inTree( node.child, test ) then return true end
  end
  while node do
    if node == test then return true end
    node = node.next
  end
  return false
end  
  
function SynTree:cut( node )
  if inTree( node, self.current ) then
    self.current = node.parent
    smachine.depth = smachine.depth -1
  end
  self.cutbuffer = node
  if node.prev then
    node.prev.next = node.next
  end
  if node.next then 
    node.next.prev = node.prev
  end
  node.next, node.prev = nil, nil
  if node.parent then
    if node.parent.child == node then
      node.parent.child = nil
    end
  end
end

function SynTree:paste( node )
  if self.cutbuffer == nil then return end
  
  -- displace 'node' approach
  self.cutbuffer.next = node
  self.cutbuffer.prev = node.prev
  if node.prev then 
    node.prev.next = self.cutbuffer
  end
  node.prev = self.cutbuffer
  self.cutbuffer.parent = node.parent
  if node.parent and node.parent.child == node then 
    node.parent.child = self.cutbuffer
  end
end

function SynTree:load( node, chunk )
  local num, limit = 1, #chunk
  local definition = ""
  
  for num = 1, limit do
    key = string.sub( chunk, num, num )
    
    if key == '{' then 
      defmode = true
    elseif defmode then
      if key == '}' then
        defmode = false
        if smachine.tree.current then
          smachine.tree.current.meaning = definition
        end
        definition = ""
      else
        definition = definition .. key
      end
    end
    
    if not defmode and key ~= '}' then  

      if key == '\t' or key == '\n' then
        if #input > 0 then 
          smachine.tree.current = smachine.nextState( input, smachine.tree.current )
          input = ''
        end
        smachine.tree.current = smachine.nextState( key, smachine.tree.current )
      else
        input = input .. key
      end
    end
  end
end

function SynTree:altdump( node )
  
  local tmps = ' { name: "' .. node.name .. '",' 
  
  if node.meaning then
    tmps = tmps .. ' meaning: "' .. node.meaning .. '",'
  end
  
  if node.child then
    tmps = tmps .. ' child:' .. self:altdump( node.child ) 
--  else
--    tmps = tmps .. ' }'
  end
  
  if node.next then
    tmps = tmps .. ' next:' .. self:altdump( node.next )
  end
  
  return tmps .. ' }'
end
  
function SynTree:dump( node )
  
  local tmps = node.name
  local nxt = node.next
  
  if node.meaning then
    tmps = tmps .. '{' .. node.meaning .. '}'
  end
  
  if node.child then
    tmps = tmps .. '\n' .. self:dump( node.child ) .. '\t'
  else
    tmps = tmps .. '\t'
  end
  
  while nxt do
    tmps = tmps .. self:dump( nxt )
    nxt = nxt.next
  end
  
  return tmps
end
  
function SynTree:setRowPosition( x, y, node, depth )
  local first, namelen = true, 0
  local newx, returning
  
  while node do
    returning = false
    newx = x
    namelen = 7 * (#node.name + 2)
    if node.child then 
      newx = self:setRowPosition( x, y + 18, node.child, depth + 1 )
      returning = true
    end
    
    node.depth = depth
    
    if returning then
      node.x = x
      x = newx
      returning = false
    else
      node.x = x
    end
    node.xlen = namelen
    node.y = y
    
    if node.x + node.xlen > self.xhi then
      self.xhi = node.x + node.xlen
    end
    if node.y > self.yhi then 
      self.yhi = node.y
    end
        
    x = x + namelen + 12
    node = node.next
  end
  return x - (namelen + 12)
end

function SynTree:display( node )
  
  local tnode, lastnode = nil
  while node do
    
    if lastnode then
      love.graphics.line(lastnode.x + lastnode.xlen, node.y+8, node.x, node.y+8 )
    end
    
    if node.child then
      self:display( node.child )
      if node.x >= 0 and node.x < screenX and node.y >= 60 and node.y < screenY then
        love.graphics.line(node.child.x + node.child.xlen/2, node.child.y,
          node.x + node.xlen/2, node.y + 12 )
      end
    end
    
    if node.x >= 0 and node.x < screenX and node.y >= 60 and node.y < screenY then 
      if node.selected then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.rectangle("fill", node.x, node.y, node.xlen, 14)
        love.graphics.setColor( 0, 0, 0, 255 ) 
        love.graphics.print( '('.. node.name .. ')', node.x, node.y )
        love.graphics.setColor( r, g, b, a ) 
      else  
        love.graphics.print( '('.. node.name .. ')', node.x, node.y )
      end
    end
    
    lastnode = node
    node = node.next
  end

  return tnode
end

function SynTree:locate( node, x, y )
  
  local fnode = nil
  while node do
  
    if node.child then
      fnode = self:locate( node.child, x, y )
      if fnode then return fnode end
    end
    
    if x >= node.x and x <= node.x + node.xlen and
       y >= node.y and y <= node.y + 12 then
      return node
    end
    
    node = node.next
  end
  
  return nil
end

function SynTree:search( node, str )
  
  local fnode = nil
  while node do
  
    if node.child then
      fnode = self:search( node.child, str )
      if fnode then return fnode end
    end
    
    if node.name == str then
      return node
    end
    
    node = node.next
  end
  
  return nil
end

-------------------------------------------------------------
--  smachine State Machine
-------------------------------------------------------------

smachine = {}
smachine.depth = 0
smachine.state = "init"
smachine.tree = SynTree:new()
smachine.reference = SynTree:new()
smachine.refindex, smachine.refparse = nil, nil

smachine.nextState = function ( input, node ) 
  
  if smachine.state == "init" then
    
    if input == '\n' or input == '\t' or input == 'backspace' then 
      return nil
    end
    
    smachine.state = "desc"
    smachine.depth = 1;
    -- ignore the parent node passed as this will be the root node
    return smachine.tree:attach( nil, nil, input )
  end
  
  if smachine.state == "desc" then
    
    if input == '\n' then
      return node
    end
    
    if input == '\t' then
      smachine.state = "wait"
      return node
    end
    
    if input == 'backspace' then      
      smachine.tree:cut( node )
      if node.prev then return node.prev
      elseif node.parent then
        return node.parent
      else
        smachine.level = 0
        smachine.state = "init"
        smachine.root = nil
        return nil
      end
    end
    
    smachine.depth = smachine.depth + 1
    return smachine.tree:attachChild( node, input )
  end
  
  if smachine.state == "wait" then
    
    if input == '\n' then
      local nxt
      if node.child then
        smachine.depth = smachine.depth + 1
        nxt = node.child
        while nxt.next do nxt = nxt.next end
        return nxt
      else
        smachine.state = "desc"        
        return node
      end
    end
    
    if input == '\t' then
      if smachine.depth == 1 then return node end
      
      smachine.depth = smachine.depth - 1
      if smachine.depth == 0  then
        smachine.state = "init"
        smachine.root = nil
        return nil
      else
        smachine.state = "wait"
        return node.parent
      end
    end
    
    if input == 'backspace' then      
      smachine.tree:cut( node )
      smachine.state = "desc"
      if node.prev then return node.prev
      elseif node.parent then
        return node.parent
      else
        smachine.level = 0
        smachine.state = "init"
        smachine.tree.root = nil
        return nil        
      end
    end
    
    smachine.state = "desc"
    return smachine.tree:attach( node.parent, node, input )
  end
  
  -- fall thru must be error mode
  return node
end

function smachine.travParseAdd( pnode, subname, fullname )

  local chr = subname:sub( 1, 1 )
  local restof = subname:sub(2)
  local lastnode = nil
  
  while pnode and pnode.name ~= chr do
    lastnode = pnode
    pnode = pnode.next
  end
  if pnode == nil then
    pnode = smachine.refparse:attach( lastnode.parent, lastnode, chr )
  end
    
  if #restof > 0 then
    smachine.travParseAdd( pnode, restof, fullname )
  else
    pnode.meaning = fullname
  end
  
end

function smachine.mkRefTables( node )
    
  if node == nil then return end
  
  if node.child then
    smachine.mkRefTables( node.child )
  end
  
  while node do
    smachine.refindex[node.name] = node
    smachine.travParseAdd( smachine.refparse, node.name, node.name )
    node = node.next
  end
  
end

-------------------------------------------------------------
--  love Event Handlers defined
-------------------------------------------------------------

MyShift = {[","]="<", ["."]=">", ["/"]="?", [";"]=":", ["'"]='"', 
           ["["]="{", ["]"]="}", ["\\"]="|",["`"]="~", ["1"]="!", ["2"]="@",
           ["3"]="#", ["4"]="$", ["5"]="%", ["6"]="^",
           ["7"]="&", ["8"]="*", ["9"]="(", ["0"]=")", ["-"]="_", ["="]="+" }
blurb = 3
scrollX, scrollY = 0, 0
input, definition, filename, searchstr, message = "", "", "", "", nil
defmode, shift, editmode, autoscroll = false, false, false, true
floadmode, fsavemode, falt, searchmode, mousehold = false, false, false, false, false


function love.load(arg)
  
  if arg and arg[#arg] == "-debug" then require("mobdebug").start() end
  
  screenX, screenY  = love.graphics.getWidth(), love.graphics.getHeight()
  love.window.setTitle( "(Tiny) Tree Editor" )
  
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

function adjustSelectScroll()
  
  while smachine.tree.select.x > screenX*0.8 or smachine.tree.select.x < 10 or
      smachine.tree.select.y > screenY*0.8 or smachine.tree.select.y < 60 do
    
    autoscroll = false
    
    if smachine.tree.select.x > screenX*0.8 then
      scrollX = scrollX - screenX*0.2 
    elseif smachine.tree.select.x < 10 then
     scrollX = scrollX + screenX*0.2
    end
    if smachine.tree.select.y > screenY*0.8 then
      scrollY = scrollY - screenY*0.2 
    elseif smachine.tree.select.y < 60 then
      scrollY = scrollY + screenY*0.2
    end
    
    smachine.tree.xhi, smachine.tree.yhi = 0, 0
    smachine.tree:setRowPosition( 10 + scrollX, 60 + scrollY, smachine.tree.root, 1 )
  end
end

function love.keypressed( key )
  if key == 'lshift' or key == 'rshift' then
    shift = true
  end
  if blurb > 0 then 
    if key == 'escape' then blurb = 0
    else blurb = blurb - 1
    end  
  end
end

function love.keyreleased( key ) 
  local p = smachine.tree.select
    
  if blurb > 0 then return 
  elseif blurb == 0 then
    blurb = -1
    return
  end
  
  if key == 'lshift' or key == 'rshift' then
    shift = false
    return
  end
  
  if key == 'home' and p then
    p.selected = false
    smachine.tree.select = smachine.tree.root
    smachine.tree.select.selected = true
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
    smachine.tree.select = p
    adjustSelectScroll()
    return
  end
  if key == 'up' and p and p.parent then
    p.selected = false
    p = p.parent
    p.selected = true
    smachine.tree.select = p
    adjustSelectScroll()
    return
  end
  if key == 'left' and p and p.prev then
    p.selected = false
    p = p.prev
    p.selected = true
    smachine.tree.select = p
    adjustSelectScroll()
    return
  end
  if key == 'right' and p and p.next then
    p.selected = false
    p = p.next
    p.selected = true
    smachine.tree.select = p
    adjustSelectScroll()
    return
  end
  
  if key == 'delete' and smachine.tree.select then
    local newselect = smachine.tree.select.parent
    if newselect == nil then return end
    
    smachine.tree.select.selected = false
    smachine.tree:cut( smachine.tree.select )
    smachine.tree.select = newselect
    newselect.selected = true
    return
  end
  if key == 'insert' and smachine.tree.cutbuffer then
    smachine.tree:paste( smachine.tree.select )
    return
  end
  
  if key == 'f1' then
    floadmode = true
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
      smachine.tree.root = nil
      smachine.tree:load( smachine.tree.root, ss )
      return
    elseif key == 'escape' then
      floadmode = false
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
        ss = 'root =' .. smachine.tree:altdump( smachine.tree.root ) .. ';'
      else
        ss = smachine.tree:dump( smachine.tree.root )
      end
      local file = io.open(filename, "w+")
      if file == nil then
        message = "!!failure to saveful!!"
        return
      end      
      file:write( ss ); file:close()
      message = "**save successful**"
      return
    elseif key == 'escape' then 
      fsavemode = false
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
    local tmp
      tmp = smachine.reference
      smachine.tree.state = smachine.state
      smachine.reference = smachine.tree 
      smachine.tree = tmp
      smachine.state = tmp.state
      smachine.refindex = {}
      smachine.refparse = SynTree:new()
      smachine.mkRefTables( smachine.reference.root )
    return
  end
  
  if key == 'f4' then
    searchmode = true
    return
  end
  if searchmode then
    if key == 'return' then
      searchmode = false
      local node = smachine.tree:search( smachine.tree.root, searchstr )
      if node then
        smachine.tree.select.selected = false
        smachine.tree.select = node
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
  
  if key == 'f10' then love.event.quit() return end
  
  -- at this point filter out any key events we don't want to record
  --
  if key == 'down' or key == 'up' or key == 'left' or key == 'right' or
     key == 'insert' or key == 'delete' or key == 'home' then return end
    
  if key == '\\' and not editmode and smachine.tree.select then
    editmode = true;
    input = smachine.tree.select.name 
    return
  end
  if key == '\\' and editmode then 
    editmode = false
    input = ''
    return
  end
  
  message = nil
    
  if key == '[' and shift then 
    defmode = true
    if editmode and smachine.tree.select.meaning then
      definition = smachine.tree.select.meaning
    end
    return 
  end 
  
  if defmode then
    if key == ']' and shift then
      defmode = false
      if editmode then
        smachine.tree.select.meaning = definition
        input = ''
        editmode = false
      else        
        if smachine.tree.current then 
          smachine.tree.current.meaning = definition
        end
      end
      definition = ""
      return
    end
    if key == 'return' or key == 'space' or key == 'tab' then key = '  '
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
  
  autoscroll = true
  
  if key == 'backspace' then
    if #input > 0 then
      input = string.sub( input, 1, #input - 1 )
      return
    end
    smachine.tree.current = smachine.nextState( key, smachine.tree.current )
    return
  end

  if key == 'tab' then
    if #input > 0 then 
      if editmode then
        smachine.tree.select.name = input
        editmode = false
        return
      else
        smachine.tree.current = smachine.nextState( input, smachine.tree.current )
      end
      input = ''
    end
    smachine.tree.current = smachine.nextState( '\t', smachine.tree.current )
    return
  end
  
  if key == 'return' then 
    if #input > 0 then 
      if editmode then
        smachine.tree.select.name = input
        editmode = false
      else
        smachine.tree.current = smachine.nextState( input, smachine.tree.current )
      end
      input = ''    
    end
    smachine.tree.current = smachine.nextState( '\n', smachine.tree.current )
    return
  end
  
  if key == 'space' then
    input = input .. ' '
    return
  end
  if shift then
    local k = MyShift[key]
    if k then
      input = input .. k
    else
      input = input .. key:upper()
    end    
    return
  end
  input = input .. key
end
  
function love.mousepressed(x, y, button )
  
  if button ~= 1 then return end
  
  local node = smachine.tree:locate( smachine.tree.root, x, y )
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
  
function love.mousereleased(x, y, button )
  
  if button ~= 1 then return end
  
  mousehold = false
  
  local node = smachine.tree:locate( smachine.tree.root, x, y )
  if node then
    smachine.tree.select.selected = false
    smachine.tree.select = node
    node.selected = true
  end
  
end

function love.update()
  
  if smachine.tree.root then
    smachine.tree.xhi, smachine.tree.yhi = 0, 0
    smachine.tree:setRowPosition( 10 + scrollX, 74 + scrollY, smachine.tree.root, 1 )
    
    if autoscroll then
      if smachine.tree.xhi > screenX*0.8 then scrollX = scrollX - screenX*0.2 end
      if smachine.tree.yhi > screenY*0.8 then scrollY = scrollY - screenY*0.2 end
    end
    
  end
end

function love.draw ()  
  
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

  love.graphics.setColor( 100, 50, 0, 255 )
  love.graphics.rectangle( "fill", 0, 6, screenX, 32 )
  love.graphics.setColor( 0, 100, 50, 255 )
  love.graphics.rectangle( "fill", 0, 38, screenX, 32 )
  love.graphics.setColor( 255, 255, 255, 255 )
  
  if searchmode then
    love.graphics.print( "Search for Node: " .. searchstr, 8, 8 )
  elseif floadmode then
    love.graphics.print( "File to Load: " .. filename, 8, 8 )
  elseif fsavemode then
    love.graphics.print( "File to Save: " .. filename, 8, 8 )
  elseif shift then
    love.graphics.print( "Use Arrow/Home/End to navigate for editing. Insert/Delete to cut&paste, `\\' to edit.", 8, 8) 
    love.graphics.print( "F1 Load/F2 Save/F3 Reference Swap/F4 Search/../F10 Exit", 8, 24 ) 
  elseif message then
    love.graphics.print( message, 8, 8 )
  else
    love.graphics.print( "Enter WORDS `enter' to descend and `tab' to remain at that level. Use `{' your_meaning `}' to add meaning. Shift=more help", 8, 8) 
  end

  if #input > 0 then
    love.graphics.print( input, 10 , 55 )
  end
  if defmode then
    love.graphics.print('{' .. definition, 10, 40 )
  end

  if smachine.tree.current then
    if not shift then
      if editmode then
        if smachine.tree.select.meaning then
          love.graphics.print('SELECT="' .. smachine.tree.select.name .. '" {' .. smachine.tree.select.meaning .. '} depth=' .. smachine.tree.select.depth, 8, 24 )    
        else
          love.graphics.print('SELECT="' .. smachine.tree.select.name .. '" depth=' .. smachine.tree.select.depth, 8, 24 )
        end
      else
        if smachine.tree.current.meaning then
          love.graphics.print('CURRENT="' .. smachine.tree.current.name .. '" {' .. smachine.tree.current.meaning .. '} state=' .. smachine.state .. ' depth=' .. smachine.depth, 8, 24 )
        else
          love.graphics.print('CURRENT="' .. smachine.tree.current.name .. '" state=' .. smachine.state .. ' depth=' .. smachine.depth, 8, 24 )
        end        
      end
    end
    
    smachine.tree:display( smachine.tree.root )
  
    if smachine.state == "desc" then
      love.graphics.circle("fill", smachine.tree.current.x + smachine.tree.current.xlen/2, 
        smachine.tree.current.y + 22, 8 )
    elseif smachine.state == "wait" then
      love.graphics.circle("fill", smachine.tree.current.x + smachine.tree.current.xlen + 8, 
        smachine.tree.current.y + 6, 8 )
    end
    
  else
    love.graphics.circle("fill", 20, 78, 8 )    
  end
  
end
