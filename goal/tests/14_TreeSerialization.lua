require "goal"

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

local function nodeData(name) return function(...)
    Data(name) (
        Key "tag:INTEGER", 
        Key "id:INTEGER", -- ID of codeblock object
        "location",
        ...
    )
end end

--------------------------------------------------------------------------------
-- Database functions
--------------------------------------------------------------------------------

local function dbInit()
    DataSet("sqlite3", "14_TreeSerialization.db")--, --[[Do not delete]] false)
    -- Define tables:
    nodeData "blocks" (
        Key "entry_num:INTEGER", 
        "entry_tag:INTEGER"
    )
    nodeData "functions" (
        "name", 
        "type",
        "block_tag:INTEGER" 
    )
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

    -- GoAL Events:

    EventCase(FuncDecl "n") (receiver "n")(
    ) (Otherwise) (
        Store "functions" (Tag, id "n", location "n", name "n", typeof "n", Body.id "n")
    )

    Event(BlockStmt "n") (
        ForPairs "k" "v" (List "n") (
            Store "blocks" (Tag, id "n", location "n", var "k", id "v")
        )
    )
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
        select * from functions
    ]]) do
        pretty_print(result)
    end
    
    Analyze (
        Files(FindPackages("src"))
    )
end

main()