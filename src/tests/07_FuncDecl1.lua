-- Simple case
Event(FuncDecl "f") (
    Printf("Simple: '%s'.\n", name "f")
)

Analyze (
    Files "src/tests/sample.go"
)

-- Simple conditional
Event(FuncDecl "f") (
    CheckExists(Expr(Receiver "f"),
        Yes(Printf "Cond1"), No(Printf "Cond2")
    )
)

Analyze (
    Files "src/tests/sample.go"
)

Event(FuncDecl "f") (
    CheckExists(Expr(Receiver "f"),
        Yes(Printf("Conditional: Function '%s' has receiver type '%s'.\n", name "f", Receiver.type "f")),
        No( Printf("Conditional: Function '%s' has no receiver type.\n", name "f") )
    )
)

Analyze (
    Files "src/tests/sample.go"
)