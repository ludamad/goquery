DataSet "12_AdvancedSQL.db"

Data "methods" (
    Key "name", Key "type", Key "receiver_type", "location"
)

Data "functions" (
    Key "name", Key "type", "location"
)

Data "interface_reqs" (
    Key "interface", Key "name", Key "type", "location"
)

Data "type_declarations" (
    Key "name", "location"
)

Data "type_method_inherits" (
    Key "type", Key "embedded_type"
)

EventCase(FuncDecl "f") (receiver "f")(
    Store "methods" (name "f", type "f", receiver.type "f", location "f")
) (Otherwise) (
    Store "functions" (name "f", type "f", location "f")
)

local function CaseEmpty(var) return Case(Equal(Len(var), 0)) end 

EventCaseType (
    TypeSpec "n", Type "n"
) (InterfaceType) (
    ForAll "f" (Type.Methods.List "n") (
       Store "interface_reqs" (name "n", name "f", type "f", location "f")
    )
) (StructType) (
    ForAll "f" (Type.Fields.List "n") (
       CaseEmpty(Names "f") (
           Store "type_method_inherits" (name "n", type "f") -- We inherit methods of all embedded types
       )
    )
)
Event (TypeSpec "n") (Store "type_declarations" (name "n", location "n"))

Analyze (Files(FindFiles "src/go-future/types"))


local results = DataQuery [[
select iface, tname from
    (select i.interface as iface, m.receiver_type AS rtype, count(*) AS satisfied from 
        methods m join interface_reqs i on m.name=i.name and m.type=i.type
        group by i.interface, m.receiver_type
    ) 
   join
    (select t.name as tname, embedded_type as etype from 
        type_declarations t left join type_method_inherits tmi 
        on t.name=tmi.type
    )
   where rtype in ("*" || etype, etype, tname, "*" || tname)
   group by iface, tname
   having sum(satisfied) == (select count(*) from interface_reqs iq where iq.interface = iface)
]]

for result in values(results) do
    print("Type '" .. result.tname .. "' satisfies '" .. result.iface .. "'")
end