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

-- Helper routines

function concat_names(obj1, obj2)
    return block(
        push(obj1 .. ".name"), push_string ".", push(obj2 .. ".name"),
        concat(3)
    )
end

-- Triggers

FuncDecl "Func" (
    concat_names("Func", "Package"),
    push "Func.Signature.type",
    check_exists "Func.Receiver.type" (
        yes ( push "Func.location", save_tuple "functions" ),
        no  ( push {"Func.Receiver.type", "Func.location"}, save_tuple "methods" )
    )
)

-- 'Parameterized' trigger
TypeSpec("TypeSpec", InterfaceType "Interface") (
    for_all("Method", "Interface.Methods") (
        push "TypeSpec.name",
        push "Method.name",
        push "Method.type",
        push "Method.location",
        save_tuple "interface_reqs"
    )
)

local ifaces = {}
local types = {}

for _, t in ipairs(LuaLoadTupleDicts "interface_reqs") do
    local iface = ifaces[t.interface] or {funcs = {}} 
    ifaces[t.interface] = iface
    table.insert(iface.funcs, {t.name, t.type})
end

for _, t in ipairs(LuaLoadTupleDicts "functions") do
    local type = types[t.type] or {funcs = {}} 
    types[t.type] = type
    table.insert(type.funcs, {t.name, t.type})
end

for _, typetup in ipairs(types) do
    local tname, type = typetup.name, typetup.type
    for _, ifacetup in ipairs(ifaces) do
        local iname, iface = ifacetup.name, ifacetup.type
        local has_all = true
        for _, r in ipairs(iface.funcs) do
            local has = false
            for _, has in ipairs(type.funcs) do
                if r[1] == has[1] and r[2] == has[2] then
                    has = true; break
                end
            end
            if not has then has_all = false; break end
        end
        if has_all then
            print(tname, "satisfies", iname)
        end
    end
end
