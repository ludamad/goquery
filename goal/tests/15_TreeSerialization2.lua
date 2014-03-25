require "goal"

local node_types = require "tests.helper.helper15"

--------------------------------------------------------------------------------
-- Database functions
--------------------------------------------------------------------------------

local function dbInit()
    DataSet("sqlite3", "15_TreeSerialization2.db")--, --[[Do not delete]] false)

    for nt in values(node_types) do
        nt:create_table()
    end

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

    for nt in values(node_types) do
        nt:emit_event(Tag)
    end
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

    Analyze (
        Files(FindPackages("src"))
    )
end

main()
