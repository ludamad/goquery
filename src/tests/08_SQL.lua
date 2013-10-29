TupleSet "methods" (
    Fields("name", "type", "receiver_type", "location"),
    Keys("name", "type", "receiver_type")
)

TupleSet "functions" (
    Fields("name", "type", "location"),
    Keys("name", {attr="type", datatype="int"})
)

TupleSet "interface_reqs" (
    Fields("interface", "name", "type", "location"),
    Keys("interface", "name", "type")
)

Event(FuncDecl "f") (
    CheckExists(Expr(Receiver "f"),
        Yes(
            SaveTuple( Set "methods", Fields(name "f", type "f", Receiver.type "f", location "f") )
        ),
        No (
            SaveTuple( Set "functions", Fields(name "f", type "f", location "f") )
        )
    )
)

Event(TypeSpec "t", InterfaceType "i") (
    ForAll(Methods "i", "m") (
        SaveTuple( Set "interface_reqs", Fields(name "t", name "m", type "m", location "m"))
    )
)

Analyze (
    Files "src/tests/sample.go"
)

SqlPrint "SELECT * from functions"
SqlPrint "SELECT * from methods"
SqlPrint "SELECT * from interface_reqs"

-- Run a really ugly query
print("SOLVING:")
local itypes = '(SELECT DISTINCT interface FROM interface_reqs)'
local subexpr1 = '(SELECT COUNT(*) FROM interface_reqs INNER JOIN methods USING (name, type) WHERE receiver_type = T.name and interface = I.interface)'
local subexpr2 = '(SELECT COUNT(*) FROM interface_reqs WHERE interface == I.interface)'
SqlPrint [[
    SELECT T.name, I.interface as iname FROM types as T, $interface_types as I
    WHERE $subexpr1 == $subexpr2
]]