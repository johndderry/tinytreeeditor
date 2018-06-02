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
Keystroke.input = ""

Keystroke.init = function ()
  
  Keystroke.maincursor = Cursor:new( { 
      colorOn={r=0.8,g=0.8,b=0.5}, colorOff={r=0.5,g=0.5,b=0.8},
      height=fontheight, width=fontsize} )
  Keystroke.maincursor.y = 14 + 3*fontheight
  Keystroke.maincursor:off()
  Keystroke.altcursor = Cursor:new( { 
      colorOn={r=0.8,g=0,b=0.8}, colorOff={r=0,g=0.8,b=0.8},
      height=fontheight, width=fontsize} )
  Keystroke.altcursor.y = 14 + 3*fontheight
  Keystroke.altcursor:off()
  
  Keystroke.cursor = Keystroke.maincursor
end

Keystroke.nextState = function( key, node )
  
  if Keystroke.state == "pass" then 
    if key == sys.backspace then
      Keystroke.input = string.sub( Keystroke.input, 1, #Keystroke.input - 1 )
      Keystroke.depth = Keystroke.depth + 1
      return node
    end
    if key == '\n' or key == '\t' then
      Keystroke.depth = 0
      Keystroke.input = ''
      return node
    end
    if key == sys.left or key == sys.right or key == sys.up or key == sys.down then 
      return node 
    end
    Keystroke.input = Keystroke.input .. key
    Keystroke.depth = Keystroke.depth + 1
    return node
  end
    
  if Keystroke.state ~= "pass" then    
    if key == sys.right then
      Keystroke.state = "hyper"
      Keystroke.hindex = 1
      Keystroke.hyper = {}
      if node == nil then
        Keystroke.tree:genList( Keystroke.hyper, Keystroke.tree.root )
      else
        Keystroke.tree:genList( Keystroke.hyper, node )
      end
      Keystroke.cursor.width = sys.getwidth( Keystroke.hyper[Keystroke.hindex] ) - sys.getwidth( Keystroke.input )
      return node
    end
    if key == sys.left then
      Keystroke.state = "cont"
      Keystroke.hyper = nil
      Keystroke.cursor.width = fontsize
      return node
    end
    if Keystroke.state == "hyper" then
      if key == sys.up then
        if Keystroke.hindex < #Keystroke.hyper then Keystroke.hindex = Keystroke.hindex + 1 end
        Keystroke.cursor.width = sys.getwidth( Keystroke.hyper[Keystroke.hindex] ) - sys.getwidth( Keystroke.input )
      end
      if key == sys.down then
        if Keystroke.hindex > 1 then Keystroke.hindex = Keystroke.hindex - 1 end
        Keystroke.cursor.width = sys.getwidth( Keystroke.hyper[Keystroke.hindex] ) - sys.getwidth( Keystroke.input )
      end
      return node
    else
      if key == sys.up or key == sys.down then return node end
    end
  end      
        
  if Keystroke.state == "term" then
    if key == sys.backspace then
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
     Keystroke.state == "error" or Keystroke.state == "hyper" then
    
    if key == "\n" or key == "\t" then
      Keystroke.depth = 0
      Keystroke.input = ''
      Keystroke.state = "init"
      Keystroke.cursor.width = fontsize
      return node
    end
    
    if key == sys.backspace then
      Keystroke.input = string.sub( Keystroke.input, 1, #Keystroke.input - 1 )
      Keystroke.depth = Keystroke.depth - 1
      if Keystroke.depth == 0 then Keystroke.state = "init" end
      if Keystroke.state == "hyper" then
        Keystroke.hyper = Keystroke.tree:firstTerm( node.parent )
      end
      return node.parent
    end

    Keystroke.cursor.width = fontsize
    
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
Syntax.state = "init"
Syntax.tree = SynTree:new()
Syntax.reference = SynTree:new()

Syntax.nextState = function ( input, node ) 
  
  if Syntax.state == "init" then
    
    if input == '\n' or input == '\t' or input == sys.backspace then 
      return nil
    end
    
    if Keystroke.state == "pass" or Keystroke.state == "valid" or 
       Keystroke.state == "term" or Keystroke.state == "hyper" then
      Syntax.state = "accept"
      -- ignore the parent node passed as this will be the root node
      return Syntax.tree:attach( nil, nil, input )
    else
      return nil
    end    
  end
  
  if Syntax.state == "accept" then
    if input == '\n' then Syntax.state = "desc"
    elseif input == '\t' then Syntax.state = "wait"
    end
    return node 
  end
    
  if Syntax.state == "desc" then
    
    if input == '\n' then
      return Syntax.tree:innerChild( node )
    end
    
    if input == '\t' then
      if Syntax.tree.current.next then
        return Syntax.tree:outerChild( Syntax.tree.current.next )
      else
        Syntax.state = "wait"
        return node
      end
    end
    
    if input == sys.backspace then      
      local prev = node.prev
      Syntax.tree:cut( node )
      if prev then return prev
      elseif node.parent then
        return node.parent
      else
        Syntax.level = 0
        Syntax.state = "init"
        Syntax.root = nil
        return nil
      end
    end
    
    if Keystroke.state == "pass" or Keystroke.state == "valid" or 
       Keystroke.state == "term" or Keystroke.state == "hyper" then
      Syntax.state = "accept"
      return Syntax.tree:attachChild( node, input )
    else
      return node
    end
  end
  
  if Syntax.state == "wait" then
    
    if input == '\n' then
      local nxt
      if node.child then
        nxt = node.child
        while nxt.next do nxt = nxt.next end
        return nxt
      else
        Syntax.state = "desc"        
        return node
      end
    end
    
    if input == '\t' then
      if node.parent then
        if node.parent.next == nil then  
          return node.parent
        else
          return Syntax.tree:outerChild( node.parent )
        end
      else  
        return node
      end      
    end
    
    if input == sys.backspace then
      local prev = node.prev
      Syntax.tree:cut( node )
      Syntax.state = "desc"
      if prev then return prev
      elseif node.parent then
        return node.parent
      else
        Syntax.level = 0
        Syntax.state = "init"
        Syntax.tree.root = nil
        return nil        
      end
    end
    
    if Keystroke.state == "pass" or Keystroke.state == "valid" or 
       Keystroke.state == "term" or Keystroke.state == "hyper" then
      Syntax.state = "accept"
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

Syntax.mkRefTables = function( node, makeindex )
    
  if node == nil then return end
  
  if node.child then
    Syntax.mkRefTables( node.child )
  end
  
  if node.name:sub(1,1) ~= '#' then
    if makeindex then Syntax.refindex[node.name] = node end
    Syntax.travParseAdd( Keystroke.tree.root, nil, node.name, node.name )
  end
  
  if node.next then Syntax.mkRefTables( node.next, makeindex ) end
end

function nextToken( chunk )
  
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
  
Syntax.altload = function( parent, chunk )
  
  local node, token = SynNode:new( parent )
  
  local indx = string.find( chunk, '{')
  chunk = string.sub( chunk, indx+1 )
  
  while true do
    token, chunk = nextToken( chunk )
    if token == '}' then break
    elseif token == "name:" then    node.name, chunk = nextToken( chunk )
    elseif token == "meaning:" then node.meaning, chunk = nextToken( chunk )
    elseif token == "next:" then    node.next, chunk = Syntax.altload( parent, chunk )
    elseif token == "child:" then   node.child, chunk = Syntax.altload( node, chunk )
    end
  end
  return node, chunk
end

Syntax.load = function( chunk )
  local key, num, limit = nil, 1, #chunk
  local defmode, definition = false, ""
  
  for num = 1, limit do
    key = string.sub( chunk, num, num )
    
    if key == '{' then 
      defmode = true
    elseif defmode then
      if key == '}' then
        defmode = false
        if #Keystroke.input == 0 and Syntax.tree.current then
          Syntax.tree.current.meaning = definition
          definition = ""
        end
      else
        definition = definition .. key
      end
    end
    
    if not defmode and key ~= '}' then  

      if key == '\t' or key == '\n' then
        if #Keystroke.input > 0 then 
          Syntax.tree.current = Syntax.nextState( Keystroke.input, Syntax.tree.current )
          Keystroke.input = ''
          if #definition > 0 then
            Syntax.tree.current.meaning = definition
            definition = ''
          end
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
    tmps = tmps .. ' child:' .. Syntax.altdump( node.child ) .. ','
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