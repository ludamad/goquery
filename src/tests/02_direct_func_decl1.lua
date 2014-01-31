goal.PushEvent("FuncDecl", goal.SimpleBytecodeContext(
    {"FuncDecl: Found %s '%s' at '%s'\n"}, {
        CONSTANT(0),
        SPECIAL_PUSH(0, 0, goal.SMEMBER_type),
        SPECIAL_PUSH(0, 0, goal.SMEMBER_name),
        SPECIAL_PUSH(0, 0, goal.SMEMBER_location),
        PRINTFN(4)
    }
))

Analyze (
    Files "tests/sample.go"
)