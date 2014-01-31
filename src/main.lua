-- Note, prelude.lua is already loaded.

local BOLD_YELLOW = "1;32"

local prompt = Colorify(">>> ", BOLD_YELLOW) 

goal.ReadLineAddHistory("test")

print(goal.ReadLine(prompt))