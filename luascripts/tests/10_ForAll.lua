require "goal.prelude"

local testLoopable = ("This\n.is\n.the\n.correct\n.result!\n"):split(".")
-- Direct test
goal.SimpleRun({testLoopable}, {
    CONSTANT(0), PUSH_NIL(),
    --[[2]] NEXT(5),
    PRINTFN(1),
    --[[4]] JMP(2)
})

-- 'Unit' test
do
    local unit = ForPairs "k" "v" (var "obj") (Printf("Loop got %d: %s", var "k", var "v"))
    local bc = goal.Compile(goal.CodeParse(unit), "obj")
    prettyBytecode(bc)
    bc.Exec(goal.GlobalSymbolContext, goal.NullFileContext, goal.NewObjectStack(testLoopable))
end

-- Integration test

EventCaseType (
    TypeSpec "n", Type "n"
) (InterfaceType) (
    ForAll "m" (Type.Methods.List "n") (
        Printf("Interface %s needs method %s\n", name "n", type "m")
    )
)
Analyze(Files "tests/interface.go")