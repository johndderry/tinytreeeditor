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
    selected = false,
    open = true
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
    xoffs = 0, yoffs = 0, page = 0,
    state = "init"
  }
  return setmetatable( self, {__index = SynTree} )
end

function SynTree:clone( node, parent )
  
  local first, prev, newnode = nil, nil
  
  while node do
    newnode = SynNode:new(parent)
    newnode.prev = prev
    if prev then prev.next = newnode end
    newnode.name = node.name 
    newnode.meaning = node.meaning
    if node.child then
      newnode.child = self:clone( node.child, newnode )
    end
    
    if first == nil then first = newnode end
    prev = newnode
    node = node.next
  end

  return first
end
  
function SynTree:attach( parent, atpoint, name )
  local node = SynNode:new( parent )
  node.name = name
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
  node.next = parent.child
  if( parent.child ) then parent.child.prev = node end
  parent.child = node 
  
  return node
end

function SynTree:merge( dest, pos, mtree )
  local node
  if pos == "child" then
    node = dest.child
    if node then
      while node.next do node = node.next end
      node.next = mtree.root 
      node.next.prev = node
      node = node.next
      while node do
        node.parent = dest
        node = node.next
      end
    else
      dest.child = mtree.root 
      node = dest.child
      while node do
        node.parent = dest
        node = node.next
      end
    end
    mtree.root = nil
    return
  end
  
  if pos == "sibling" then
    node = mtree.root
    node.prev = dest
    while node.next do
      node.parent = dest.parent
      node = node.next
    end
    node.parent = dest.parent
    node.next = dest.next
    if node.next then node.next.prev = node end
    dest.next = mtree.root
    mtree.root = nil
    return
  end
  
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
    if node.prev then
      self.current = node.prev
    else
      self.current = node.parent
    end
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
  
  local cutbuffer = self:clone( self.cutbuffer )
  
  -- displace 'node' approach
  cutbuffer.next = node
  cutbuffer.prev = node.prev
  if node.prev then 
    node.prev.next = cutbuffer
  end
  node.prev = cutbuffer
  cutbuffer.parent = node.parent
  if node.parent then 
    if node.parent.child == node then 
      node.parent.child = cutbuffer
    end
  else
    if self.root == node then 
      self.root = cutbuffer
    end    
  end
end

function SynTree:innerChild( node )
  
  local savenode = node
  while node.parent and node.prev == nil do
    node = node.parent
  end
  if node.prev then node = node.prev end
  
  while node.child do  
    node = node.child
    while node.next do node = node.next end
  end
  
  --Syntax.state = "desc"
  return node
end

function SynTree:outerChild( node )
  
  local savenode = node
  while node.parent and node.next == nil do
    node = node.parent
  end
  if node.next then node = node.next end
  
  while node.child do  
    node = node.child
    while node.prev do node = node.prev end
  end
  
  --Syntax.state = "desc"
  return node
end

function SynTree:setListPosition( x, y, node, depth, getwidth )
  
  while node do
    node.x, node.y = x + 12*depth + self.xoffs, y + self.yoffs
    y = y + 1.2*fontheight
    if node.child and node.open then 
      y = self:setListPosition( x, y, node.child, depth+1, getwidth)
    end
    node.xlen = getwidth( node.name )
    node = node.next
  end
  return y
end
  
function SynTree:setTreePosition( x, y, node, getwidth )
  local namelen
  local newx, returning
  local spacing = 4
  
  while node do
    --io.write('setRowPosition: '..node.name..'\n')
    returning = false
    --newx = x
    namelen = getwidth( '(' .. node.name .. ')' )
    if node.child and node.open then 
      newx = self:setTreePosition( x, y + 1.5*fontheight, node.child, getwidth )
      returning = true
    end
    
    node.x = x + self.xoffs
    if returning then
      if newx > x+namelen+spacing then
        x = newx
      else
        x = x + namelen + spacing      
      end  
    else
      x = x + namelen + spacing      
    end
    node.xlen = namelen
    node.y = y + self.yoffs
    
    node = node.next
  end
  --return x - (namelen + spacing)
  return x
end

function SynTree:display( node, treemode, graphics, getwidth )
  
  local tnode, lastnode = nil
  while node do
    
    if treemode and lastnode then
      graphics.line(lastnode.x + getwidth('('..lastnode.name..')'), node.y+fontheight/2, node.x, node.y+fontheight/2 )
    end
    
    if node.child and node.open then
      self:display( node.child, treemode, graphics, getwidth )
      if treemode and node.name:sub(1,1) ~= '#' and
          node.x >= 0 and node.x < screenX and 
          node.y >= treeYbegin and node.y < screenY then
        graphics.line(node.child.x + node.child.xlen/2, node.child.y,
          node.x + node.xlen/2, node.y + fontheight )
      end
    end
    
    if node.x >= -screenX/2 and node.x < screenX and node.y >= treeYbegin and node.y < screenY then 
      if node.selected then
        --local r, g, b, a = love.graphics.getColor()
        graphics.rectangle("fill", node.x, node.y, node.xlen, fontheight )
        graphics.setColor( 0, 0, 0, 1 ) 
        graphics.setBackgroundColor(1, 1 ,1 ,1)
        if treemode then
          graphics.print( '('.. node.name ..')', node.x, node.y )
        else
          graphics.print( node.name, node.x, node.y )
        end
        graphics.setColor( 1, 1, 1, 1 )
        graphics.setBackgroundColor( 0, 0, 0, 1 )         
        if not treemode and node.meaning then
          graphics.print(' {' .. node.meaning .. '}', node.x + node.xlen, node.y )
        end
      elseif treemode then
        if not node.open then
          graphics.setColor( 0.8, 0, 0, 1 )         
          graphics.rectangle("fill", node.x, node.y, node.xlen, fontheight )
          graphics.setColor( 1, 1, 1, 1 )
        end
        graphics.print( '('.. node.name ..')', node.x, node.y )
      elseif node.meaning then
        if not node.open then
          graphics.setColor( 0.8, 0, 0, 1 )         
          graphics.rectangle("fill", node.x, node.y, node.xlen, fontheight )
          graphics.setColor( 1, 1, 1, 1 )
        end
        graphics.print( node.name, node.x, node.y )
        graphics.setColor( 1, 0.4, 0.4, 1 ) 
        graphics.print( '{' .. node.meaning .. '}', node.x + node.xlen+ 4, node.y )
        graphics.setColor( 1, 1, 1, 1 ) 
      else        
        if not node.open then
          graphics.setColor( 0.8, 0, 0, 1 )         
          graphics.rectangle("fill", node.x, node.y, node.xlen, fontheight )
          graphics.setColor( 1, 1, 1, 1 )
        end
        graphics.print( node.name, node.x, node.y )
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
  
    if node.child and node.open then
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
  
    if node.child and node.open then
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

function SynTree:split( node )
  
  local t = SynTree:new()
  t.xoffs = node.x - self.root.x + self.xoffs
  t.yoffs = node.y - self.root.y + self.yoffs
  t.root = node
  if( node.parent and node.parent.child == node ) then
    node.parent.child = nil;
  end
  node.parent = nil;
  if node.prev then
    node.prev.next = nil
  end
  node.prev = nil
  local n = node.next
  while n do
    n.parent = nil
    n = n.next
  end
  return t
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