
local t = goal.CurrentTime()

local schema = require "schema"

print("Preparing GoAL event system took " .. goal.TimeSince(t) .. "ms")
io.flush(io.stdout)

local printgo = require "printgo"

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------
local function file_exists(name)
    local f = io.open(name,"r")
    if f ~= nil then io.close(f) end
    return f ~= nil
end

local function get_param(argv, flag)
    for i,v in pairs(argv) do
        local match = v:match(flag .. ":(.*)")
        match = match or (v == flag and argv[i+1])
        if match then
            assertf(match, "Expected parameter but none given for '%s'!", flag)
            assertf(not match:match("^[%-]+[^%s]+$"), "Aborting because parameter '%s' for '%s' looks like a flag.", match, flag)
            return match
        end 
    end
    return nil
end

--------------------------------------------------------------------------------
-- Database init
--------------------------------------------------------------------------------
local function dbInit(args)
    local already_existed = file_exists(args.db_loc)
    if args.must_already_exist then
        error("No DB found. Have you ran 'godb init'?")
    end

    DataSet(args.db_type, args.db_loc, --[[Don't delete existing (for SQLite)]] false)

    schema.init_database()

    if not already_existed then
        for val in values {"tag", "id" } do
            DataExec([[create index idx1_]].. val ..[[ on node_data(]]..val..[[)]])
            DataExec([[create index idx2_]].. val ..[[ on node_links(]]..val..[[)]])
            DataExec([[create index idx3_]]..val ..[[ on FuncDecl(]]..val..[[)]])
        end
        DataExec [[create table tags (
            tag INTEGER primary key autoincrement,
            commit_id TEXT
        )]]
    end
end

--------------------------------------------------------------------------------
-- Database previous commit data removal
--------------------------------------------------------------------------------
local function removeTag(tag)
--    print("Removing data inserted with tag " .. tag .. ".")

    for table in values {"node_data", "node_links", "FuncDecl", "tags"} do
       DataExec([[
        delete from ]] .. table .. [[ 
         where tag == ]] .. tag
       )
    end
end
local function removeCommit(commit)
    print("Removing current commit data for '"..commit.."'.")

    local test = DataQuery([[
        select tag from tags
            where commit_id == ']]..commit..[[';
    ]])

    for entry in values(test) do
        print("Removing " .. entry.tag)
        removeTag(entry.tag)
    end
end

--------------------------------------------------------------------------------
-- Get unique tag for commit
--------------------------------------------------------------------------------
local function dbGetTag(commit) 
    local results = DataQuery("select tag from tags where commit_id == '" .. commit .. "';")
    assert(#results == 1, "Should have one tag per commit!")
    return results[1].tag
end

local function dbNewTag(commit) 
    removeCommit(commit)
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
-- Initialization and main functions
-- For all functions, 'args' has these members:
--  - commit
--  - db_type
--  - db_loc
--------------------------------------------------------------------------------
local __INITIALIZED = false
local function init(args)
    if not __INITIALIZED then
        timeit("dbInit", function()
            dbInit(args)
        end)
        __INITIALIZED = true
    end
end 
local __DUMPED = false
local function dump(args)
    assert(not __DUMPED, "Cannot dump twice!") ; __DUMPED = true

    init(args)

    defineEvents(dbNewTag(args.commit))

    local pkgs = FindPackages("src")
    local files = {"src/main.go"}
    for i=1,#files do
        pkgs[#pkgs +1] = files[i]
    end
    Analyze (
        Files(pkgs)
    )
    print("Dumping data for commit '" .. args.commit .. "'.")
end

local function remove(args) 
    init(args)
    removeCommit(args.commit)
end

local function query(sql)
    return values(DataQuery(sql))
end

local cprint = goal.ColorPrint -- Shorthand for ANSI colored printing

local function type_decl_query(tag)
    return DataQuery([[
        select * from node_data nd 
        where nd.tag == ]]..tag..[[ and kind == 'TypeSpec'
        order by data
    ]])
end

local function func_decl_query(tag)
    return DataQuery([[
        select * from FuncDecl fd 
        where fd.tag == ]]..tag..[[
        order by receiver, name
    ]])
end

local function type_decls(args) 
    init(args)
    local count = 1
    cprint("31", "Number\t")
    cprint("32", "Name\n")
    cprint("32", "------------------------------------------\n")

    local tag = dbGetTag(args.commit)

    for td in values(type_decl_query(tag)) do
        cprint("31", count .. '\t')
        cprint("32", td.data .. '\n')
        count = count + 1
    end
end

local function func_decls(args, handle_methods) 
    init(args)
    local count = 1
    cprint("31", "Number\t")
    if handle_methods then cprint("36", "Receiver\t\t") end
    cprint("32", "Name\n")
    cprint("32", "------------------------------------------\n")

    local tag = dbGetTag(args.commit)

    for fd in values(func_decl_query(tag)) do
        if handle_methods then
            if fd.receiver ~= nil then
                cprint("31", count .. '\t')
                cprint("36", fd.receiver .. '\t')
                cprint("32", fd.name .. '\n')
                count = count + 1
            end
        else
            if fd.receiver == nil then
                cprint("31", count .. '\t')
                cprint("32", fd.name .. '\n')
                count = count + 1
            end
        end
    end
end

local function queryit(tag)
     local func_results = DataQuery([[
            select F.tag, "FuncDecl" as kind, "block" as label, 
                    F.location, F.end_location, F.name as data, F.type, F.id as id, N.link_id, NULL as link_number
            from FuncDecl F join node_links N
            where F.tag == N.tag and F.tag == ]] .. tag .. [[ and F.block_id == N.id
     ]])
     local node_results = DataQuery([[
            select N.tag, D.kind, N.label, 
                    D.location, D.end_location, D.data, D.type, N.id, N.link_id, N.link_number
            from node_links N join  node_data D
            where ]] .. tag .. [[ == N.tag and D.tag == N.tag and N.id == D.id
            order by link_number
    ]])

    local id_map = {}
    local function ensure_id(id)
        local obj = id_map[id] or {links = {}}
        id_map[id] = obj

        return obj
    end

    local roots = {}
    for r in valuesAll(func_results, node_results) do
        if r.kind == "File" then
            roots[r.id] = ensure_id(r.id)
        end
        local obj = ensure_id(r.id)
        obj.tag, obj.kind, obj.location, obj.end_location = r.tag, r.kind, r.location, r.end_location
        obj.data = r.data
        if r.link_id then 
            local elem = ensure_id(r.link_id)
            append(obj.links, elem)
        end
    end

    return roots
end

local function root_decls(roots)
    local decls = {}

    for _,r in pairs(roots) do
        for i in values(r.links) do
            if i.kind == "GenDecl" then
                for j in values(i.links) do
                    if j.data then
                        append(decls, j)
                    end
                end
            elseif i.data then
                append(decls, i)
            end
        end
    end

    return decls
end

local cols = {['+'] = 36, TypeSpec = 34}
local function diff(args)
    init(args)

    local roots1 = queryit(dbGetTag(args.commit1))
    local roots2 = queryit(dbGetTag(args.commit2))

    local f1 = root_decls(roots1)
    local f2 = root_decls(roots2)

 --   for r in values(f1) do
 --       printgo.print_go(r, function() return "31" end)
 --   end

--    local sym = {}
--    for f in values(f1) do sym[f.data] = true end
--    for f in values(f2) do 
--        if not sym[f.data] then 
--            print("New function: " .. f.data) 
--            print("Source: " .. printgo.get_source(f))
--        end
--    end
end

local function sql_test(args)
    init(args)
    timeit("sql_test", function()
        queryit(dbGetTag(args.commit))
    end)
end
 
return {
    remove = remove,
    dump = dump,
    funcs = function(args) func_decls(args, false) end,
    methods = function(args) func_decls(args, true) end,
    types = type_decls,
    test = sql_test,
    diff = diff
}
