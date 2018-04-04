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
  local self = {
    next = nil, prev = nil, child = nil,
    name = "Node",
    selected = false
  }
  self.parent = parent
  return setmetatable( self, {__index = SynNode} )
end

-------------------------------------------------------------
--  SynTree class
-------------------------------------------------------------

SynTree = {}

function SynTree:new()
  local self = {
    root = nil, current = nil, select = nil,
    state = "init"
  }
  return setmetatable( self, {__index = SynTree} )
end

function SynTree:attach( parent, atpoint, name )
  local node = SynNode:new( parent )
  node.name = name
  node.depth = Syntax.depth
  if parent == nil and atpoint == nil then
    node.selected = true
    self.root, self.current, self.select = node, node, node
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
  --node.depth = Syntax.depth
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
    Syntax.depth = Syntax.depth -1
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

function SynTree:innerChild( node )
  
  local savenode = node
  while node.parent and node.prev == nil do
    --Syntax.depth = Syntax.depth -1
    node = node.parent
  end
  if node.prev then node = node.prev end
  
  while node.child do  
    node = node.child
    --Syntax.depth = Syntax.depth + 1
    while node.next do node = node.next end
  end
  
  --Syntax.state = "desc"
  return node
end

function SynTree:outerChild( node )
  
  local savenode = node
  while node.parent and node.next == nil do
    --Syntax.depth = Syntax.depth -1
    node = node.parent
  end
  if node.next then node = node.next end
  
  while node.child do  
    node = node.child
    --Syntax.depth = Syntax.depth + 1
    while node.prev do node = node.prev end
  end
  
  --Syntax.state = "desc"
  return node
end

  
function SynTree:setListPosition( x, y, node, depth )
  
  while node do
    node.x, node.y = x + 12*depth, y
    y = y + 1.2*fontheight
    if node.child then y = self:setListPosition( x, y, node.child, depth+1) end
    node.xlen = font:getWidth( node.name )
    node = node.next
  end
  return y
end
  
function SynTree:setRowPosition( x, y, node, depth )
  local first, namelen = true, 0
  local newx, returning
  local spacing = 4
  
  while node do
    returning = false
    newx = x
    namelen = font:getWidth( '(' .. node.name .. ')' )
    if node.child then 
      newx = self:setRowPosition( x, y + 1.5*fontheight, node.child, depth + 1 )
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
    
    x = x + namelen + spacing
    node = node.next
  end
  return x - (namelen + spacing)
end

function SynTree:display( node, treemode )
  
  local tnode, lastnode = nil
  while node do
    
    if treemode and lastnode then
      love.graphics.line(lastnode.x + font:getWidth('('..lastnode.name..')'), node.y+fontheight/2, node.x, node.y+fontheight/2 )
    end
    
    if node.child then
      self:display( node.child, treemode )
      if treemode and node.x >= 0 and node.x < screenX and node.y >= treeYbegin and node.y < screenY then
        love.graphics.line(node.child.x + node.child.xlen/2, node.child.y,
          node.x + node.xlen/2, node.y + fontheight )
      end
    end
    
    if node.x >= 0 and node.x < screenX and node.y >= treeYbegin and node.y < screenY then 
      if node.selected then
        --local r, g, b, a = love.graphics.getColor()
        love.graphics.rectangle("fill", node.x, node.y, node.xlen, fontheight )
        love.graphics.setColor( 0, 0, 0, 255 ) 
        if treemode then
          love.graphics.print( '('.. node.name ..')', node.x, node.y )
        else
          love.graphics.print( node.name, node.x, node.y )
        end
        love.graphics.setColor( 255, 255, 255, 255 )
        if not treemode and node.meaning then
          love.graphics.print(' {' .. node.meaning .. '}', node.x + node.xlen, node.y )
        end
      elseif treemode then
        love.graphics.print( '('.. node.name ..')', node.x, node.y )
      elseif node.meaning then
        love.graphics.print( node.name .. ' {' .. node.meaning .. '}', node.x, node.y )
      else
        love.graphics.print( node.name, node.x, node.y )
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

function SynTree:isSibling( node, name )

  while node do      
    if node.name == name then
      return node
    end
    node = node.next
  end
  
  return nil
end

function SynTree:genList( list, node )

  if node.meaning then table.insert( list, node.meaning ) end
  if node.child then
    self:genList( list, node.child )
  end
  if node.next then self:genList( list, node.next ) end
  
end

function SynTree:fixLinks( parent, prev, node )
  
  node.parent = parent
  node.prev = prev
  
  if( node.child ) then self:fixLinks( node, nil, node.child ) end
  if( node.next ) then  self:fixLinks( parent, node, node.next ) end
end

function SynTree:sortLevel( parent, dir )
  
  if parent == nil or parent.child == nil then return end
  
  local more, changed = true
  local node, nextnode
  while more do
    node = parent.child
    nextnode = node.next
    changed = false
    while node and nextnode do
      local nextnext = nextnode.next
      if (dir and nextnode.name < node.name) or
         (not dir and nextnode.name > node.name) then
        node.next = nextnode.next
        if node.next then
          node.next.prev = node
        end
        nextnode.prev = node.prev
        if nextnode.prev then
          nextnode.prev.next = nextnode
        end
        nextnode.next = node
        node.prev = nextnode
        if node == parent.child then
          parent.child = nextnode
        end
        if nextnode == self.current then
          self.current = node
        end
        
        changed = true
        --node = nextnode
        nextnode = nextnext
      else
        node = nextnode
        nextnode = nextnext
      end
    end
    if not changed then more = false end
  end
end
  
function SynTree:insertRoot( name )
  
  local saveroot, tmp = self.root, self.root
  if self.select then self.select.selected = false end
  
  local node = self:attach( nil, nil, name )
  while tmp do
    tmp.parent = node
    tmp = tmp.next
  end
  node.child = saveroot
  Syntax.state = "wait"
  Syntax.depth = 1
end

function SynTree:deleteRoot( )
  
  if self.root.child == nil then return end
  
  local wasSelected, wasCurrent = self.root.selected
  if self.root == self.current then wasCurrent = true
  else                              wasCurrent = false
  end
  
  self.root = self.root.child
  if wasCurrent then 
    self.current = self.root
    while self.current.next do self.current = self.current.next end
    Syntax.state = "wait"
  end
  if wasSelected then
    self.root.selected = true
    self.selected = self.root 
  end
  
  local node = self.root 
  while node do
    node.parent = nil
    node = node.next
  end
end

-------------------------------------------------------------
--  Cursor class
-------------------------------------------------------------

Cursor = {}

function Cursor:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.altmode, o.active = false, false
  o.x, o.y = 8, 0
  o.count, o.max = 100, 100
  return o
end

function Cursor:on()
  self.r, self.g, self.b = self.colorOn.r, self.colorOn.g, self.colorOn.b
end

function Cursor:off()
  self.r, self.g, self.b = self.colorOff.r, self.colorOff.g, self.colorOff.b
end

function Cursor:update()
  self.count = self.count - 1
  if self.count < 0 then
    self.count = self.max
    if active then
      if self.altmode then self:off()
      else self:on() end
      self.altmode = not self.altmode
    end
  end  
end