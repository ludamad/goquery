DataSet "11_DataSchemas.db"

Data "methods" (
    Key "name", Key "type", Key "receiver_type", "location"
)

Data "functions" (
    Key "name", Key "type", "location"
)

Data "interface_reqs" (
    Key "interface", Key "name", Key "type", "location"
)

Data "types" (
    Key "name", "location"
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
)

Event(TypeSpec "n") (Store "types" (name "n", location "n"))

Analyze (Files "tests/interface.go")

local interface_types='(SELECT DISTINCT interface FROM interface_reqs)'
local subexpr1='(SELECT COUNT(*) FROM interface_reqs INNER JOIN methods USING (name, type) WHERE receiver_type = T.name and interface = I.interface)'
local subexpr2='(SELECT COUNT(*) FROM interface_reqs WHERE interface == I.interface)'
local queryTemplate = ([[
    SELECT T.name, I.interface as iname FROM types as T, %s as I
        WHERE %s == %s
]])

local results = DataQuery(queryTemplate:format(interface_types, subexpr1, subexpr2))

for result in values(results) do
    print("Type '" .. result.name .. "' satisfies '" .. result.iname .. "'")
end

