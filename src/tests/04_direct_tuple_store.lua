goal.DefineTuple({"Name", "ID"}, {"Name"})

goal.SimpleRun({
    "Foo", "0", 
    "Loaded tuple (%s, %s)\n"
}, {
    CONSTANT(0), CONSTANT(1),
    SAVE_TUPLE(0,0, 2),
    CONSTANT(0),
    LOAD_TUPLE(0,0, 1),
    CONSTANT(2),
    SPECIAL_PUSH(0,0, 0),
    SPECIAL_PUSH(0,0, 1),
    PRINTFN(3)
})