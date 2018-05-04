local def = {}

def.getwidth = function( string )
  return 8 * #string
end

def.fontheight = function() 
  return 8 
end

def.graphics = allegro
def.quit = allegro.quit

def.escape = "Escape"
def.space = "space"
def.backspace = "BackSpace"
def.tab = "Tab"
def._return = "Return"
def.leftshift = "Shift_L"
def.rightshift = "Shift_R"
def.home = "Home"
def._end = "End"
def.delete = "Delete"
def.insert = "Insert"
def.left = "Left"
def.right = "Right"
def.up = "Up"
def.down = "Down"
def.pageup = "Prior"
def.pagedown = "Next"
def.f1 = "F1"
def.f2 = "F2"
def.f3 = "F3"
def.f4 = "F4"
def.f5 = "F5"
def.f6 = "F6"
def.f7 = "F7"
def.f8 = "F8"
def.f9 = "F9"
def.f10 = "F10"

Punctuation = {comma=',', period='.', slash='/', semicolon=';', apostrophe="'",
  bracketleft='[', bracketright=']', backslash = '\\', minus='-', equal='=', grave='`'}
  
return def
