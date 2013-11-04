-- Without macros:
Event(TypeSpec "n") (
    Case(TypeCheck(InterfaceType, Type "n"))(
        Print "InterfaceType\n"
    )(TypeCheck(MapType, Type "n"))(
        Print "MapType\n"
    )
)
Analyze(Files "src/tests/typesExample.go")

Event(TypeSpec "n") (
    CaseType(Type "n")(InterfaceType)(
        Print "InterfaceType\n"
    )(MapType)(
        Print "MapType\n"
    )
)

Analyze(Files "src/tests/typesExample.go")

EventCaseType (
    TypeSpec "n", Type "n"
) (InterfaceType) (
    Print "InterfaceType\n"
) (MapType) (
    Print "MapType\n"
)
Analyze(Files "src/tests/typesExample.go")