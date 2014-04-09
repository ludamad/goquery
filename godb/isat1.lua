local function has_arg(str)
    return table.contains(sys_args, str)
end

DataSet("sqlite3", "isat1.db", not has_arg "--keep")  

Data "methods" (
    Key "name", Key "type", Key "receiver_type", "location"
)

Data "functions" (
    Key "name", Key "type", "location"
)

Data "structs" (
    Key "type", "location"
)

Data "interfaces" (
    Key "interface", "location"
)

Data "interface_reqs" (
    Key "interface", Key "name", Key "type", "location"
)

Data "interface_inherits" (
    Key "type", Key "embedded_type"
)

Data "struct_inherits" (
    Key "type", Key "embedded_type"
)

EventCase(FuncDecl "f") (receiver "f")(
    Store "methods" (name "f", typeof "f", receiver.basetype "f", location "f")
) (Otherwise) (
    Store "functions" (name "f", typeof "f", location "f")
)

local function CaseEmpty(var) return Case(Equal(Len(var), 0)) end 

EventCaseType (
    TypeSpec "n", Type "n"
) (InterfaceType) (
    Store "interfaces" (name "n", location "n"),
    ForAll "f" (Type.Methods.List "n") (
       CaseEmpty(Names "f") (
            Store "interface_inherits" (name "n", basetype "f") -- We inherit requirements of all embedded types
       ) (Otherwise) (
            Store "interface_reqs" (name "n", name "f", typeof "f", location "f")
       )
    )
) (StructType) (
    Store "structs" (name "n", location "n"),
    ForAll "f" (Type.Fields.List "n") (
       CaseEmpty(Names "f") (
           Store "struct_inherits" (name "n", basetype "f") -- We inherit methods of all embedded types
       ) -- Ignore other members, not used for isat
    )
)

local function dumpSatisfications()
    local results
    timeit("ISATQuery", function()
    results = DataQuery [[
        WITH RECURSIVE 
        -- Interface embedding:
                iface_embed_closure(iface, embed) 
        AS (
                select I.interface, I.interface from interfaces I 
        UNION 
                select C.iface, H.embedded_type 
                from iface_embed_closure C join interface_inherits H
                where H.type = C.embed
        ),
        -- Struct embedding:
                struct_embed_closure(type, embed) 
        AS (
                select I.type, I.type 
                from structs I 
        UNION 
                select C.type, H.embedded_type 
                from struct_embed_closure C join struct_inherits H
                where H.type == C.embed
        ),
        -- Finding all the requirements of an interface:
                iface_reqs_closure(iface, name, signature) 
        AS (
                select C.iface, R.name, R.type
                from iface_embed_closure C
                join interface_reqs R
                where C.embed == R.interface
        ),
        -- Finding all the methods of a struct:
                struct_methods_closure(struct, name, signature) 
        AS (
                select C.type, M.name, M.type
                from struct_embed_closure C
                join methods M
                on C.embed  == M.receiver_type
        ),
        -- Finding all the satisfactions counts:
                struct_iface_sat_counts(struct, iface, satisfied)
        AS (
                select C.struct, R.iface, count(*)
                from struct_methods_closure C join iface_reqs_closure R
                on C.name == R.name and C.signature == R.signature
                group by R.iface, C.struct
        ),
        -- Count the amount of interface requirements:
                iface_req_counts(iface, needed)
        AS (
                select C.iface, count(*)
                from iface_reqs_closure C
                group by C.iface
        ),
        -- Find all the satisfactions:
                struct_iface_sat(struct, iface)
        AS (
                select C.struct, I.iface
                from struct_iface_sat_counts C join iface_req_counts I
                on C.iface == I.iface and C.satisfied == I.needed
        )
        -- Selection:
        SELECT * from struct_iface_sat;
    ]]
    end)
    for result in values(results) do
        print("Type '" .. result.struct .. "' satisfies '" .. result.iface .. "'")
    end
end

if true or has_arg "--dump" then
timeit("ISATDump", function()
    Analyze (Files(FindPackages "src"))
end)
end

if true or has_arg "--isat" then
    dumpSatisfications()
end
