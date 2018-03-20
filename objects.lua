-------------------------------------------------------------
--    (Tiny) Tree Editor
--    Author: John Derry (johndderry@yahoo.com)
--    Version: 1.0
--    No Rights Reserved
-------------------------------------------------------------

-------------------------------------------------------------
--  Keystroke State Machine
-------------------------------------------------------------

Keystroke = {}
Keystroke.depth = 0
Keystroke.state = "pass"
Keystroke.input, Keystroke.suggest = ""

Keystroke.init = function ()
  
  Keystroke.maincursor = Cursor:new( { 
      colorOn={r=200,g=200,b=128}, colorOff={r=128,g=128,b=200},
      height=fontheight, width=fontsize} )
  Keystroke.maincursor.y = 14 + 3*fontheight
  Keystroke.maincursor:off()
  Keystroke.altcursor = Cursor:new( { 
      colorOn={r=200,g=0,b=200}, colorOff={r=0,g=200,b=200},
      height=fontheight, width=fontsize} )
  Keystroke.altcursor.y = 14 + 3*fontheight
  Keystroke.altcursor:off()
  
  Keystroke.cursor = Keystroke.maincursor
end

Keystroke.nextState = function( key, node )
  
  if Keystroke.state == "pass" then 
    if key == "backspace" then
      Keystroke.input = string.sub( Keystroke.input, 1, #Keystroke.input - 1 )
      Keystroke.depth = Keystroke.depth + 1
      return node
    end
    if key == "\n" or key == "\t" then
      Keystroke.depth = 0
      Keystroke.input = ''
      return node
    end
    Keystroke.input = Keystroke.input .. key
    Keystroke.depth = Keystroke.depth + 1
    return node
  end
    
  if Keystroke.state == "term" then
    if key == "backspace" then
      Keystroke.input = string.sub( Keystroke.input, 1, #Keystroke.input - 1 )
      Keystroke.depth = Keystroke.depth - 1
      Keystroke.state = "continue"
      return Keystroke.savedparent
    end
    if key == "\n" or key == "\t" then
      Keystroke.depth = 0
      Keystroke.input = ''
      Keystroke.state = "init"
    end
    return node
  end
  
  if Keystroke.state == "init" and Keystroke.tree then
    Keystroke.state = "continue"
    node = Keystroke.tree.root
    Keystroke.tree.current = node
  end
  
  if Keystroke.state == "continue" or Keystroke.state == "valid" or
     Keystroke.state == "error" then
    
    if key == "\n" or key == "\t" then
      Keystroke.depth = 0
      Keystroke.input = ''
      Keystroke.state = "init"
      return node
    end
    
    if key == "backspace" then
      Keystroke.input = string.sub( Keystroke.input, 1, #Keystroke.input - 1 )
      Keystroke.depth = Keystroke.depth - 1
      if Keystroke.depth == 0 then Keystroke.state = "init" end
      return node.parent
    end

    local tmpn = Keystroke.tree:isSibling( node, key )
    if tmpn == nil then
      Keystroke.state = "error"
      Keystroke.cursor:on()
      return node
    end
    Keystroke.depth = Keystroke.depth + 1
    Keystroke.cursor:off()    
    if tmpn.meaning then
      Keystroke.state = "valid"
    else
      Keystroke.state = "continue"
    end
    
    Keystroke.input = Keystroke.input .. key
    
    if tmpn.child == nil then 
      Keystroke.state = "term"
      Keystroke.savedparent = tmpn
    end
    
    return tmpn.child
  end
  
end

-------------------------------------------------------------
-- Syntax State Machine
-------------------------------------------------------------

Syntax = {}
Syntax.depth = 0
Syntax.state = "init"
Syntax.tree = SynTree:new()
Syntax.reference = SynTree:new()

Syntax.nextState = function ( input, node ) 
  
  if Syntax.state == "init" then
    
    if input == '\n' or input == '\t' or input == 'backspace' then 
      return nil
    end
    
    if Keystroke.state == "pass" or Keystroke.state == "valid" or Keystroke.state == "term" then
      Syntax.state = "desc"
      Syntax.depth = 1;
      -- ignore the parent node passed as this will be the root node
      return Syntax.tree:attach( nil, nil, input )
    else
      return nil
    end    
  end
  
  if Syntax.state == "desc" then
    
    if input == '\n' then
      return node
    end
    
    if input == '\t' then
      Syntax.state = "wait"
      return node
    end
    
    if input == 'backspace' then      
      Syntax.tree:cut( node )
      if node.prev then return node.prev
      elseif node.parent then
        return node.parent
      else
        Syntax.level = 0
        Syntax.state = "init"
        Syntax.root = nil
        return nil
      end
    end
    if Keystroke.state == "pass" or Keystroke.state == "valid" or Keystroke.state == "term" then
      Syntax.depth = Syntax.depth + 1
      return Syntax.tree:attachChild( node, input )
    else
      return node
    end
  end
  
  if Syntax.state == "wait" then
    
    if input == '\n' then
      local nxt
      if node.child then
        Syntax.depth = Syntax.depth + 1
        nxt = node.child
        while nxt.next do nxt = nxt.next end
        return nxt
      else
        Syntax.state = "desc"        
        return node
      end
    end
    
    if input == '\t' then
      if Syntax.depth == 1 then return node end
      
      Syntax.depth = Syntax.depth - 1
      if Syntax.depth == 0  then
        Syntax.state = "init"
        Syntax.root = nil
        return nil
      else
        Syntax.state = "wait"
        return node.parent
      end
    end
    
    if input == 'backspace' then      
      Syntax.tree:cut( node )
      Syntax.state = "desc"
      if node.prev then return node.prev
      elseif node.parent then
        return node.parent
      else
        Syntax.level = 0
        Syntax.state = "init"
        Syntax.tree.root = nil
        return nil        
      end
    end
    
    if Keystroke.state == "pass" or Keystroke.state == "valid" or Keystroke.state == "term" then
      Syntax.state = "desc"
      return Syntax.tree:attach( node.parent, node, input )
    else
      return node
    end    
  end
  
  -- fall thru must be error mode
  return node
end

Syntax.travParseAdd = function( node, parent, subname, fullname )

  local chr = subname:sub( 1, 1 )
  local restof = subname:sub(2)
  local lastnode = nil
  
  while node and node.name ~= chr do
    lastnode = node
    node = node.next
  end
  if node == nil then
    if lastnode then
      node = Keystroke.tree:attach( parent, lastnode, chr )
    elseif parent == nil then
      node = Keystroke.tree:attach( nil, nil, chr )
    else
      node = Keystroke.tree:attachChild( parent, chr )
    end
  end
    
  if #restof > 0 then
    Syntax.travParseAdd( node.child, node, restof, fullname )
  else
    node.meaning = fullname
  end
  
end

Syntax.mkRefTables = function( node )
    
  if node == nil then return end
  
  if node.child then
    Syntax.mkRefTables( node.child )
  end
  
  while node do
    Syntax.refindex[node.name] = node
    Syntax.travParseAdd( Keystroke.tree.root, nil, node.name, node.name )
    node = node.next
  end
  
end

Syntax.load = function( node, chunk )
  local key, num, limit = nil, 1, #chunk
  local defmode, definition = false, ""
  
  for num = 1, limit do
    key = string.sub( chunk, num, num )
    
    if key == '{' then 
      defmode = true
    elseif defmode then
      if key == '}' then
        defmode = false
        if Syntax.tree.current then
          Syntax.tree.current.meaning = definition
        end
        definition = ""
      else
        definition = definition .. key
      end
    end
    
    if not defmode and key ~= '}' then  

      if key == '\t' or key == '\n' then
        if #Keystroke.input > 0 then 
          Syntax.tree.current = Syntax.nextState( Keystroke.input, Syntax.tree.current )
          Keystroke.input = ''
        end
        Syntax.tree.current = Syntax.nextState( key, Syntax.tree.current )
      else
        Keystroke.input = Keystroke.input .. key
      end
    end
  end
end

Syntax.altdump = function( node )
  
  local tmps = ' { name: "' .. node.name .. '",' 
  
  if node.meaning then
    tmps = tmps .. ' meaning: "' .. node.meaning .. '",'
  end
  if node.child then
    tmps = tmps .. ' child:' .. Syntax.altdump( node.child ) 
  end
  if node.next then
    tmps = tmps .. ' next:' .. Syntax.altdump( node.next )
  end
  
  return tmps .. ' }'
end
  
Syntax.dump = function( node )
  
  local tmps = node.name
  local nxt = node.next
  
  if node.meaning then
    tmps = tmps .. '{' .. node.meaning .. '}'
  end
  if node.child then
    tmps = tmps .. '\n' .. Syntax.dump( node.child ) .. '\t'
  else
    tmps = tmps .. '\t'
  end  
  while nxt do
    tmps = tmps .. Syntax.dump( nxt )
    nxt = nxt.next
  end
  
  return tmps
end