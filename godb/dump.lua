local schema = require "schema"

--------------------------------------------------------------------------------
-- Database functions
--------------------------------------------------------------------------------

local function dbInit(args)
    print("dbInit ", args.db_loc)
    DataSet(args.db_type, args.db_loc, --[[Don't delete existing (for SQLite)]] false)

    schema.init_database()

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
    schema.emit_events(Tag)
end

--------------------------------------------------------------------------------
-- Initialization and main
--------------------------------------------------------------------------------

local function init(args)
    dbInit(args)
    defineEvents(dbGetTag(args.commit))
end 

local __INITIALIZED = false

-- dump() args:
--  - commit
--  - db_type
--  - db_loc
local function dump(args)
    if not __INITIALIZED then
        __INITIALIZED = true
        init(args)
    else 
        error("Using dump twice in an instance not supported!")
    end
    
    Analyze (
        Files(FindPackages("src"))
    )
end

return {
    dump = dump
}
