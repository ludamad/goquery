local GO_Q = _GOQUERY_API
-- Protect against undefined API accesses
setmetatable(GO_Q, {
    __index = function(self, k) error("Undefined goquery API variable " .. k .. "!")  end
})
-- Protect against undefined global accesses
setmetatable(_G, {
    __index = function(self, k) error("Undefined global variable " .. k .. "!") end
})

-- A simple binding is a key => value list set on a table
local function create_simple_binding(fname, key)
    _G[fname] = function(...)
        local values = {...}
        -- Finally, return a table operator
        return function(t)
            t[key] = values
        end
    end
end

local SIMPLE_OPERATORS = {"fields", "keys", "no", "yes"} 
for _, fname in ipairs(SIMPLE_OPERATORS) do
    create_simple_binding(fname, fname)
end

local function aggregate(t, operators)
    for _, oper in ipairs(operators) do
        oper(t)
    end
end

local function expect(t, context, fields)
    local fmap = {}
    for _,f in ipairs(fields) do
        fmap[f] = true
        assert(t[f] ~= nil, ("%s requires a %s specifier!"):format(context, f))
    end 
    for k,_ in pairs(t) do
        assert(fmap[k], ("%s does not recognize a %s specifier!"):format(context, k))
    end
end

-- 'High-level' API

function tuple_set(name)
    local t = {name = name}
    return function(...)
        aggregate(t, {...})
        expect(t, "tuple_set", {"fields", "keys"})
        GO_Q.tuple_type_define(t)
    end
end

function routine(fname)
    _G[fname] = function(...)
        local operators = {...}
        return function(t) aggregate(t, operators) end
    end
end

-- Code generation
local function add_instruction(t, type, value)
    table.insert(t.instructions, {type, value})
end

local function instruction_emitter(type, value)
    return function(t) add_instruction(t, type, value) end
end

function pop(n)
    return instruction_emitter(GO_Q.BC_POP, n or 1)
end

local PUSH_OPERATORS = {
    push_signature_type = GO_Q.BCVAL_SIGNATURE_T, 
    push_receiver_type = GO_Q.BCVAL_RECEIVER_T, 
    push_method_name = GO_Q.BCVAL_METHOD_N, 
    push_method_type = GO_Q.BCVAL_METHOD_T, 
    push_method_location = GO_Q.BCVAL_METHOD_L 
}

for k,v in pairs(PUSH_OPERATORS) do
    _G[k] = function() return instruction_emitter(GO_Q.BC_PUSH, v) end
    
end

function save_tuple(type)
    return instruction_emitter(GO_Q.BC_SAVE_TUPLE, GO_Q.tuple_type_id(type))
end

local LOOP_OPERATORS = {
    for_all_methods = 
}

for k,v in pairs(LOOP_OPERATORS) do
    _G[k] = function() return instruction_emitter(GO_Q.BC_PUSH, v) end
    
end

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