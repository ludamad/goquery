local SNodes, ENodes = goal.SNodes, goal.ENodes

local function Test(varName, ...)
    goal.PushEvent("FuncDecl", goal.Compile(goal.CodeParse(...), varName))
    Analyze (
        Files "src/tests/sample.go"
    )
end

-- Case 1 Low level node
Test(
    "FD",
    Printf("FuncDecl: Found %s '%s' at '%s'\n", 
        var "FD.type", var "FD.name", var "FD.location"
    )
)

-- Case 2 Control node
Test(
    "FD",
    Case(receiver "FD")(Print "Simple case: Meets conditional\n\n")(Otherwise)(Print "Simple case: Does not meet conditional\n")
)
-- Case 3 Control node with complex children
Test(
    "FD",
    Case(receiver "FD") (
        Printf("ConditionalCase: Function '%s' has receiver type '%s'.\n", name "FD", receiver.type "FD")
    ) (Otherwise) (
        Printf("ConditionalCase: Function '%s' has no receiver type.\n", name "FD")
    )
)