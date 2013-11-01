local C
for k, v in pairs(ops) do -- expose nodes
    _G[k] = function(...) return v(C, ...) end
end

local function Test(...)
    for v in values {...} do
        C.code.Add(
            Printf("FuncDecl: Found %s '%s' at '%s'\n", 
                stringPush "FD.type", stringPush "FD.name", stringPush "FD.location"
            )
        )
    end
    C.CompileAll()
    goal.SetEvent("FuncDecl", C.bytes)
    Analyze (
        Files "src/tests/sample.go"
    )
end

-- Call AST node creators directly, the end syntax looks a little like normal GoAL.

-- Case 1
C = goal.Compiler "FD"
Test(
    Printf("FuncDecl: Found %s '%s' at '%s'\n", 
        stringPush "FD.type", stringPush "FD.name", stringPush "FD.location"
    )
)

-- Case 2
C = goal.Compiler "FD"
Test(
    checkExists(
        objectPush "FD.Receiver",
        Print "Yes\n",
        Print "No\n"
    )
)
-- Case 3
C = goal.Compiler "FD"
Test(
    checkExists(
        objectPush "FD.Receiver",
        Printf("FuncDecl: Function '%s' has receiver type '%s'.\n",
           stringPush "FD.name", stringPush "FD.Receiver.type"
        ),
        Printf("FuncDecl: Function '%s' has no receiver type.\n",
           stringPush "FD.name"
        )
    )
)