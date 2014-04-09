-- Usage:
-- main.lua <goal directory> <db-type> <db-location> <action> <action-args>

function timeit(s,f)
    local t = goal.CurrentTime()
    f()
    print(s .. " took " .. goal.CurrentTime().Sub(t).Nanoseconds()/1000/1000 .. "ms")
end

local function main(argv, goal_dir, db_type, db_loc, action, ...)

    -- First, we must set the paths of our Lua dependencies:
    package.path = goal_dir..'/?.lua;'..goal_dir..'/.libs/?.lua'
    package.cpath = goal_dir..'/?.so;'..goal_dir..'/.libs/?.so'

    -- Next, load dependencies:
    require "goal"
    require "ErrorReporting"

    if action == "isat" then
        require "isat1"
    elseif action == "diff" then
    local db = require "db"
        local commit1, commit2 = ...
        db.diff {
            db_loc = db_loc,
            db_type = db_type,
            commit1 = commit1,
            commit2 = commit2,
            argv = argv,
        }    
    else -- Otherwise, a 1-arg db op:
    local db = require "db"
        local commit1, commit2 = ...
        local commit = (...)
        db[action] {
            db_loc = db_loc,
            db_type = db_type,
            commit = commit,
            argv = argv,
        }
    end
end

-- Convert from go-slice:
local relevant_args = {}
-- Ignore: program binary location, this script's location
for i=3,#sys_args do
    table.insert(relevant_args, sys_args[i])
end

timeit("godbmain", function()
    main(relevant_args, unpack(relevant_args))
    io.flush(io.stdout)
end)
