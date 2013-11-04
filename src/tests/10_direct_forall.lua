goal.SimpleRun({
    ("This\n.is\n.the\n.correct\n.result!\n"):split(".")
}, {
    CONSTANT(0), PUSH_NIL(),
    --[[2]] NEXT(5),
    PRINTFN(1),
    --[[4]] JMP(2)
})