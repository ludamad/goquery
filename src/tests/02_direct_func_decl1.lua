goal.SetEvent("FuncDecl", goal.SimpleBytecodeContext(
    {"FuncDecl: Found %s '%s' at '%s'\n"}, {
        STRING_CONSTANT(0),
        STRING_PUSH(0, 0, goal.SMEMBER_type),
        STRING_PUSH(0, 0, goal.SMEMBER_name),
        STRING_PUSH(0, 0, goal.SMEMBER_location),
        PRINTFN(4)
    }
))

Analyze (
    Files "src/tests/sample.go"
)