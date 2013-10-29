local C
for k, v in pairs(ops) do -- expose nodes
    _G[k] = function(...) return v(C, ...) end
end

-- Case 1
C = goal.Compiler "FD"
C.AddNode(
    Printf("FuncDecl: Found %s '%s' at '%s'\n", 
        stringPush "FD.type", stringPush "FD.name", stringPush "FD.location"
    )
)
C.CompileAll()
goal.SetEvent("FuncDecl", C.bytes)

Analyze (
    Files "src/tests/sample.go"
)

-- Case 2
C = goal.Compiler "FD"
C.AddNode(
    checkExists(
        objectPush "FD.Receiver",
        Print "Yes\n",
        Print "No\n"
    )
)
C.CompileAll()
goal.SetEvent("FuncDecl", C.bytes)

Analyze (
    Files "src/tests/sample.go"
)

-- Case 3
C = goal.Compiler "FD"
C.AddNode(
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
C.CompileAll()
goal.SetEvent("FuncDecl", C.bytes)

Analyze (
    Files "src/tests/sample.go"
)