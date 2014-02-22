require "goal"

-- Simple case
Event(FuncDecl "f") (
    Printf("Simple: '%s'.\n", name "f")
)

Analyze (
    Files "tests/sample.go"
)

-- Simple conditional
Event(FuncDecl "f") (
    Case(receiver "f")(Printf "Cond1\n")(Otherwise)(Printf "Cond2\n")
)

Analyze (
    Files "tests/sample.go"
)

Event(FuncDecl "f") (
    Case (receiver "f") (
        Printf("Conditional: Function '%s' has receiver type '%s'.\n", name "f", receiver.type "f")        
    ) (Otherwise) (
        Printf("Conditional: Function '%s' has no receiver type.\n", name "f")
    )
)

Analyze (
    Files "tests/sample.go"
)