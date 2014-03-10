require "goal"

local helper = require "tests.helper16"

--------------------------------------------------------------------------------
-- Database functions
--------------------------------------------------------------------------------

local function dbInit()
    DataSet("sqlite3", "16_TreeSerialization3.db")

    helper.init_database()

    -- TODO consider better indices
    DataExec [[create table tags (
        tag INTEGER primary key autoincrement,
        commit_id TEXT
    )]]
end

local function dbGetTag(commit) 
    -- Test getting a tag number via an auto-increment protocol:
    local result = DataExec([[
        insert into tags (commit_id) values(?)
    ]], commit)
    
    local tag, err = result.LastInsertId()
    if err ~= nil then error(err) end
    return tag
end

--------------------------------------------------------------------------------
-- Event definition functions
--------------------------------------------------------------------------------

local function defineEvents(tag)
    local Tag = Constant(tag)
    helper.emit_events(Tag)
end

--------------------------------------------------------------------------------
-- Initialization and main
--------------------------------------------------------------------------------

local function init()
    dbInit()
    defineEvents(dbGetTag "test-commit")
end 

local function main()
    init()
    
    for result in values(DataQuery [[
        select * from FuncDecl
    ]]) do
        pretty_print(result)
    end
    
    Analyze (
        Files(FindPackages("src"))
    )
end

main()
