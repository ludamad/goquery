local C
local SNodes, ENodes = goal.SNodes, goal.ENodes

local function Test(...)
    C.AddNodes({...}) ; C.CompileAll()
    goal.SetEvent("FuncDecl", C.bytes)
    Analyze (
        Files "src/tests/sample.go"
    )
end

-- Call AST node creators directly, the end syntax looks a little like normal GoAL.

-- Case 1 Low level node
C = goal.Compiler "FD"
Test(
    SNodes.Printf(C, "FuncDecl: Found %s '%s' at '%s'\n", 
        ENodes.Var "FD.type", ENodes.Var "FD.name", ENodes.Var "FD.location"
    )
)

-- Case 2 Control node
C = goal.Compiler "FD"
Test(
    Case(Receiver "FD")(Print "Simple case: Meets conditional\n\n")(Otherwise)(Print "Simple case: Does not meet conditional\n")
)
-- Case 3 Control node with complex children
C = goal.Compiler "FD"
Test(
    Case(Receiver "FD")(
        Printf("ConditionalCase: Function '%s' has receiver type '%s'.\n", name "FD", Receiver.type "FD")
    )(Otherwise) (
        Printf("ConditionalCase: Function '%s' has no receiver type.\n", name "FD")
    )
)