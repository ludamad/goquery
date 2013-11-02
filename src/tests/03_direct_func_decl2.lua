goal.SetEvent("FuncDecl", goal.SimpleBytecodeContext({
    "FuncDecl: Function '%s' has receiver type '%s'.\n",
    "FuncDecl: Function '%s' has no receiver type.\n"
}, {
    MEMBER_PUSH(0,0, goal.OMEMBER_Receiver), -- 0
    JMP_FALSE(7), -- Jump to nil case -- 1
        -- 02: Receiver is not nil
        CONSTANT(0), -- 3
        SPECIAL_PUSH(0,0, goal.SMEMBER_name), --4
        SPECIAL_PUSH(1,0, goal.SMEMBER_type), --5
        PRINTFN(3), -- 6
    JMP(10), --8
        -- 07: Receiver is nil 
        CONSTANT(1), --9
        SPECIAL_PUSH(0,0, goal.SMEMBER_name), --10
        PRINTFN(2), --11
}))

Analyze (
    Files "src/tests/sample.go"
)