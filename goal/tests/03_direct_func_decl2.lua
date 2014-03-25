require "goal"

goal.PushEvent("FuncDecl", goal.SimpleBytecodeContext({
    "FuncDecl: Function '%s' has receiver type '%s'.\n",
    "FuncDecl: Function '%s' has no receiver type.\n"
}, {
    SPECIAL_PUSH(0,0, goal.SMEMBER_name), -- 0
    SPECIAL_PUSH(0,0, goal.SMEMBER_receiver), -- 1
    SPECIAL_PUSH(2,0, goal.SMEMBER_typeof), -- 2
    PUSH(2), -- 3
    JMP_FALSE(10), -- Jump to nil case -- 4
        -- Receiver is not nil
        CONSTANT(0), PUSH(1), PUSH(3), PRINTFN(3), -- 8
    JMP(13), --9
        -- Receiver is nil 
        CONSTANT(1), PUSH(1), PRINTFN(2), --12
}))

Analyze (
    Files "tests/sample.go"
)