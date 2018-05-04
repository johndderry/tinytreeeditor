local def = {}

def.getwidth = function( string )
  return font:getWidth( string )
end

def.fontheight = function()
  return font:getHeight()
end
  
def.graphics = love.graphics
def.quit = love.event.quit

def.escape = "escape"
def.space = "space"
def.backspace = "backspace"
def.tab = "tab"
def._return = "return"
def.leftshift = "lshift"
def.rightshift = "rshift"
def.home = "home"
def._end = "end"
def.delete = "delete"
def.insert = "insert"
def.left = "left"
def.right = "right"
def.up = "up"
def.down = "down"
def.pageup = "pageup"
def.pagedown = "pagedown"
def.f1 = "f1"
def.f2 = "f2"
def.f3 = "f3"
def.f4 = "f4"
def.f5 = "f5"
def.f6 = "f6"
def.f7 = "f7"
def.f8 = "f8"
def.f9 = "f9"
def.f10 = "f10"

return def
