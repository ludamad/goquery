package.path = package.path .. ';./.libs/?.lua'
package.cpath = package.cpath .. ';./.libs/?.so'

require "goal"
require "ErrorReporting"

-- TODO: March 8, 2013 -- Figure out better solution than this for the problematic 'type' global overwrite
type_ = type
type = typeof -- Needed for interacting with other code

xpcall = unsafe_xpcall -- Go exceptions don't play nice with Lua. We ignore this...

local repl          = require 'repl.console'

for _, plugin in ipairs { 'linenoise', 'history', 'completion', 'autoreturn' } do
    repl:loadplugin(plugin)
end

local sql = require "ljsqlite3"
local conn = sql.open("14_TreeSerialization.db")  

print("Welcome to GoAL interactive mode.")
repl:run()

