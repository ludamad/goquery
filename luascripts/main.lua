-- Note, prelude.lua is already loaded.

require "Globals"
require "TableUtils"

local BOLD_YELLOW = "1;32"

require('yaml')
local obj = yaml.load [[
    a: !Test abc
    b: 5
]]
pretty_print(obj)

--local prompt = Colorify(">>> ", BOLD_YELLOW) 
--
--goal.ReadLineAddHistory("test")
--
--print(goal.ReadLine(prompt))

