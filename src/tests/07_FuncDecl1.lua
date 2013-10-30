-- Manual conditional
Event(FuncDecl "f") (
    CheckExists(Expr(Receiver "f"),
        Printf("FuncDecl: Function '%s' has receiver type '%s'.\n", name "f", Receiver.type "f"),
        No( Printf("FuncDecl: Function '%s' has no receiver type.\n", name "f") )
    )
)

Analyze (
    Files "src/tests/sample.go"
)
