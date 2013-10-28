-- Database schema

tuple_set "methods" (
    fields("name", "type", "receiver_type", "location"),
    keys("name", "type", "receiver_type")
)

tuple_set "functions" (
    fields("name", "type", "location"),
    keys("name", "type")
)

tuple_set "interface_reqs" (
    fields("interface", "name", "type", "location"),
    keys("interface", "name", "type")
)

tuple_set "types" (
    fields("name", "type", "location"),
    keys("name")
)

tuple_set "refs" (
    fields("name", "location"),
    keys("location")
)

-- Helper routines

routine "FD_push_qualified_name" (
    push_package_name(), push_string ".", push_funcdecl_name(),
    concat(3)
)

-- Triggers

FuncDecl (
    FD_push_qualified_name(),
    push_signature_type(),
    push_receiver_type(),
    check_is_nil (
        yes ( pop(), push_funcdecl_location(), save_tuple "functions" ),
        no  ( push_funcdecl_location(), save_tuple "methods" )
    )
)

-- 'Paramaterized' trigger
TypeSpec(InterfaceType) (
    for_all_methods (
        push_method_name(),
        push_method_type(),
        push_method_location(),
        save_tuple "interface_reqs"
    )
)