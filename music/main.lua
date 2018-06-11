require "classes"
require "objects"
sys = require "lovedef"

local Sdigits = {
  ['0']=0, ['1']=1, ['2']=2, ['3']=3, ['4']=4, ['5']=5, ['6']=6, ['7']=7, ['8']=8, ['9']=9,
  ['a']=10,['b']=11,['c']=12, ['d']=13, ['e']=14, ['f']=15, ['g']=16, ['h']=17, ['i']=18, ['j']=19,
  ['k']=20,['l']=21,['m']=22, ['n']=23, ['o']=24, ['p']=25, ['q']=26, ['r']=27, ['s']=28, ['t']=29,
  ['u']=30,['v']=31,['w']=32, ['x']=33, ['y']=34, ['z']=35
}

Player = {}

function Player:new(n)
  local self = {
    name = n or "player",
    schedtime = 0,
    select = 0
  }
  return setmetatable( self, {__index = Player} )
end

function Player:draw(ypos)
  love.graphics.print("hello from Player "..self.name.." sched="..self.schedtime.." select="..self.select, 5, ypos )
  return ypos + font:getHeight()
end

function Player:update(time)
  
  if( time >= self.schedtime ) then
    self.select = self.select + 1
    if self.select > #self.choices then self.select = 1 end
    
    local start = Catalog[self.choices[self.select]].tree.root
    while start and start.name:sub(1,1) == '#' do start = start.child end
    converter.reset( time )
    converter.evalAsList( start, nil )
    self.schedtime = time + Catalog[self.choices[self.select]].time
  end
  
end

CatEntry = {}

function CatEntry:new(n)
  local self = {
    name = n or "entry",
    tree = nil,
    time = 0
  }
  return setmetatable( self, {__index = CatEntry} )
end
    
function CatEntry:draw(ypos)
  love.graphics.print("hello from CatEntry "..self.name.." time="..self.time, 5, ypos )
  return ypos + font:getHeight()
end

function load_catalog()
  
  converter.quiet(true)
  
  local load = require "catalog"
  local catalog = {}
  local n
  for n = 1, #load do
    local f = io.open(load[n])
    if f then
      io.write("loading score "..load[n].."\n")
      local s = f:read("*all")
      Syntax.state = "init"
      Syntax.load( s )
      catalog[#catalog+1] = CatEntry:new(load[n])
      catalog[#catalog].tree = Syntax.tree
      Syntax.tree = SynTree:new()
      converter.reset(0)
      local start = catalog[#catalog].tree.root
      while start and start.name:sub(1,1) == '#' do start = start.child end
      converter.evalAsList( start )
      catalog[#catalog].time = converter.gettime()    
    end
  end
  converter.quiet(false)
  return catalog
end

function load_ensemble()
  local load = require "ensemble"
  local ensemble = {}
  local n
  for n = 1, #load do
    local p = load[n]
    ensemble[#ensemble+1] = Player:new(p["name"])
    ensemble[#ensemble].choices = p["choices"]
  end
  return ensemble
end

function convchoices( inp )
  local a, n
  local r = {}
  for n = 1, #inp do
    a = string.sub( inp, n, n )
    r[n] = Sdigits[a]
  end
  return r
end

input = ""
f1mode = false

function love.keyreleased( key )
  if key == "f1" then
    if f1mode then
      Ensemble[#Ensemble+1] = Player:new( tostring(#Ensemble+1) )
      Ensemble[#Ensemble].choices = convchoices( input )
      f1mode = false
    else
      f1mode = true
    end
    return
  end    
      
  if f1mode then
    input = input .. key
    return
  end
  
end

function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  alsa = require "libluaalsa"
  converter = require "convertmidi"
  font = love.graphics.setNewFont( 12 )
  Catalog = load_catalog()
  Ensemble = load_ensemble()
  if alsa then
    alsa.click = sys.click
    alsa.init()
    alsa.queueon()
    alsa.start()
    alsa.drain()
    alsa.metronome(true)
  end

end

function love.update()
  if alsa then alsa.update() end
end

Clicktime = 0

function love.draw() 
  love.graphics.print("Scores="..#Catalog.." Players="..#Ensemble.." clicktime="..Clicktime.." input="..input, 5, 5 )
  local n, y  
  y = 8 + font:getHeight()
  
  for n = 1, #Catalog do
    y = Catalog[n]:draw(y)
  end
  
  for n = 1, #Ensemble do
    y = Ensemble[n]:draw(y)
  end
end

function sys.click( time )
  local n
  Clicktime = time
  for n = 1, #Ensemble do
    Ensemble[n]:update( time )
  end
end
