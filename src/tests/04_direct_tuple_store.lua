goal.DefineTuple("MyTable", {"Name"}, {"Name"})

goal.SimpleRun({
    "Foo", "Loaded tuple (Name=%s)\n",
    0
}, {
    CONSTANT(0),
    SAVE_TUPLE(0,0, 1),

    CONSTANT(1),
    CONSTANT(0),
    LOAD_TUPLE(0,0, 1),
    CONSTANT(2),
    BIN_OP(goal.BIN_OP_INDEX),

    PRINTFN(2)
})

