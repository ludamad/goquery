-- Usage:
-- main.lua <goal directory> <db-type> <db-location> <action> <action-args>

local function main(goal_dir, db_type, db_loc, action, ...)

    -- First, we must set the paths of our Lua dependencies:
    package.path = goal_dir..'/?.lua;'..goal_dir..'/.libs/?.lua'
    package.cpath = goal_dir..'/?.so;'..goal_dir..'/.libs/?.so'

    -- Next, load dependencies:
    require "goal"
    require "ErrorReporting"

    local dump = require("dump").dump
    local diff = require("diff").diff
    --local diff = require "diff"

    if action == "dump" then
        local commit = (...)
        dump {
            db_loc = db_loc,
            db_type = db_type,
            commit = commit
        }
    elseif action == "diff" then
        local commit1, commit2 = (...)
        diff.diff {
            db_loc = db_loc,
            db_type = db_type,
            commit1 = commit1,
            commit2 = commit2
        }    
    else
        print(action, ...)
    end
end

-- Convert from go-slice:
local relevant_args = {}
-- Ignore: program binary location, this script's location
for i=3,#sys_args do
    table.insert(relevant_args, sys_args[i])
end

main(unpack(relevant_args))
