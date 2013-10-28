goal.SetEvent("FuncDecl", goal.SimpleBytecodeContext({
    "FuncDecl: Function '%s' has receiver type '%s'.\n",
    "FuncDecl: Function '%s' has no receiver type.\n"
}, {
    OBJECT_PUSH(0,0, goal.OMEMBER_Receiver),
    JMP_OBJ_ISNIL(7), -- Jump to nil case
        -- 02: Receiver is not nil
        STRING_CONSTANT(0),
        STRING_PUSH(0,0, goal.SMEMBER_name),
        STRING_PUSH(1,0, goal.SMEMBER_type),
        PRINTFN(3),
    JMP(10),
        -- 07: Receiver is nil
        STRING_CONSTANT(1),
        STRING_PUSH(0,0, goal.SMEMBER_name),
        PRINTFN(2),
    -- 10: Cleanup
    POP_OBJECTSN(1)
}))

AnalyzeAll {"src/tests/sample.go"}