functions.Take2 "RequireType" (
    function(f1, t)
        return RequireEqual(type(f1), t)
    end
)

RequireFoo = RequireType "main.Foo"
RequireFooReceiver = functions.ArgApply(Require, FooReceiver)

Event(FuncDecl "fd", 
    RequireStringArray (Receiver "fd")) (
        Printf("")
)

Analyze (
    Files "src/tests/sample.go"
)
