Data "methods" (
    Key "name", Key "type", Key "receiver_type", "location"
)

Data "functions" (
    Key "name", Key "type", "location"
)

Data "interface_reqs" (
    Key "interface", Key "name", Key "type", "location"
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

Analyze (
    Files "src/tests/interface.go",
    Database "11_DataSchemas.db"
)
