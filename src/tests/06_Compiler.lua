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
        C.CompileObjectRef "FD.type", C.CompileObjectRef "FD.name", C.CompileObjectRef "FD.location"
    )
)
--
---- Case 2 Control node
--C = goal.Compiler "FD"
--Test(
--    SNodes.CheckExists(C,
--        Expr(Receiver "FD"),
--        Yes(Print "Yes\n"), No(Print "No\n")
--    )
--)
---- Case 3 Control node with complex children
--C = goal.Compiler "FD"
--Test(
--    SNodes.CheckExists(C,
--        Expr(Receiver "FD"),
--        Yes(Printf("ConditionalCase: Function '%s' has receiver type '%s'.\n", name "FD", Receiver.type "FD")),
--        No( Printf("ConditionalCase: Function '%s' has no receiver type.\n", name "FD") )
--    )
--)