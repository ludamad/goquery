goal.DefineTuple({"Name", "ID"}, {"Name"})

goal.SimpleRun({
    "Foo", "0", 
    "Loaded tuple (%s, %s)\n"
}, {
    STRING_CONSTANT(0), STRING_CONSTANT(1),
    SAVE_TUPLE(0,0, 2),
    STRING_CONSTANT(0),
    LOAD_TUPLE(0,0, 1),
    STRING_CONSTANT(2),
    STRING_PUSH(0,0, 0),
    STRING_PUSH(0,0, 1),
    PRINTFN(3)
})