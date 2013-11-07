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

EventCaseType (
    TypeSpec "n", Type "n"
) (InterfaceType) (
    ForAll "f" (Type.Methods.List "n") (
       Store "interface_reqs" (name "n", name "f", type "f", location "f")
    )
) (StructType) (
    ForAll "f" (Type.Fields.List "n") (
       Case(Not(Names "f")) (
            Store "type_method_inherits" (name "n", type "f") -- We inherit methods of all embedded types
       )
    )
)
Event (TypeSpec "n") (Store "type_declarations" (name "n", location "n"))

Analyze (Files "src/tests/interface.go")

local results = DataQuery [[
select interface, tname from
    (select i.interface, m.receiver_type AS rtype, count(*) AS satisfied from 
        methods m join interface_reqs i on m.name=i.name and m.type=i.type
        group by i.interface, m.receiver_type
    ) 
   join 
    (select t.name as tname, embedded_type as etype from 
        type_declarations t left join type_method_inherits tmi 
        where t.name=tmi.type
    )
   where rtype in ("*" || etype, etype, tname, "*" || tname)
   group by interface, tname
   having sum(satisfied) == (select count(*) from interface_reqs iq where iq.interface = interface)
]]

for result in values(results) do
    print("Type '" .. result.tname .. "' satisfies '" .. result.interface .. "'")
end

