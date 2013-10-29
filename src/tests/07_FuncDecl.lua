local yes = Yes( 
    Printf("FuncDecl: Function '%s' has receiver type '%s'.\n", name "f", Receiver.type "f"),
)
Event(FuncDecl "f") (
    CheckExists(Expr(Receiver "f"),
        yes,
        No( Printf("FuncDecl: Function '%s' has no receiver type.\n", name "f") )
    )
)

Analyze (
    Files "src/tests/sample.go"
)