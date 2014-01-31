local type = _G.type -- DSL redefines 'type'
-- Set to a metatable that does not allow nil accesses
function nilprotect(t)
    return setmetatable(t, nilprotect_meta)
end

function values(table)
    local idx = 1
    return function()
        local val = table[idx]
        idx = idx + 1
        return val
    end
end

-- Like C printf, but always prints new line
function printf(fmt, ...) print(fmt:format(...)) end
function errorf(fmt, ...) error(fmt:format(...)) end
function assertf(cond, fmt, ...) return assert(cond, fmt:format(...)) end
-- Convenient handle for very useful function:
fmt = string.format

-- Lua table API extensions:
append = table.insert
table.next, _ = pairs {}
function table.key_list(t)
    local keys = {}
    for k, _ in pairs(t) do append(keys, k) end
    return keys
end
function table.index_of(t, val)
    for k,v in pairs(t) do if v == val then return k end end
    return nil
end
function table.merge(t1, t2) for k,v in pairs(t1) do t2[k] = v end end

-- Lua string API extension:
function string:split(sep) 
    local t = {}
    self:gsub(("([^%s]+)"):format(sep), 
        function(s) append(t, s) end
    )
    return t 
end
function string:interpolate(table)
    return (self:gsub('($%b{})', function(w) return table[w:sub(3, -2)] or w end))
end
function string:join(parts_table)
    return table.concat(parts_table, self)
end
function string:trim()
  return self:gsub("^%s*(.-)%s*$", "%1")
end
function string:trimsplit(s)
    local parts = self:split(s)
    for i,p in ipairs(parts) do parts[i] = p:trim() end
    return parts
end

--- Get a  human-readable string from a lua value. The resulting value is generally valid lua.
-- Note that the paramaters should typically not used directly, except for perhaps 'packed'.
-- @param val the value to pretty-print
-- @param tabs <i>optional, default 0</i>, the level of indentation
-- @param packed <i>optional, default false</i>, if true, minimal spacing is used
-- @param quote_strings <i>optional, default true</i>, whether to print strings with spaces
function pretty_tostring(val, --[[Optional]] tabs, --[[Optional]] packed, --[[Optional]] quote_strings)
    tabs = tabs or 0
    quote_strings = (quote_strings == nil) or quote_strings

    local tabstr = ""

    if not packed then
        for i = 1, tabs do
            tabstr = tabstr .. "  "
        end
    end
    if type(val) == "string" then val = val:gsub('\n','\\n') end
    if type(val) == "string" and quote_strings then
        return tabstr .. "\"" .. val .. "\""
    end

    local meta = getmetatable(val) 
    if (meta and meta.__tostring) or type(val) ~= "table" then
        return tabstr .. tostring(val)
    end

    local parts = {"{", --[[sentinel for remove below]] ""}

    for k,v in pairs(val) do
        table.insert(parts, packed and "" or "\n") 

        if type(k) == "number" then
            table.insert(parts, pretty_tostring(v, tabs+1, packed))
        else 
            table.insert(parts, pretty_tostring(k, tabs+1, packed, false))
            table.insert(parts, " = ")
            table.insert(parts, pretty_tostring(v, type(v) == "table" and tabs+1 or 0, packed))
        end

        table.insert(parts, ", ")
    end

    parts[#parts] = nil -- remove comma or sentinel

    table.insert(parts, (packed and "" or "\n") .. tabstr .. "}");

    return table.concat(parts)
end

function pretty_tostring_compact(v)
    return pretty_tostring(v, nil, true)
end

-- Resolves a number, or a random range
function random_resolve(v)
    return type(v) == "table" and random(unpack(v)) or v
end

--- Get a  human-readable string from a lua value. The resulting value is generally valid lua.
-- Note that the paramaters should typically not used directly, except for perhaps 'packed'.
-- @param val the value to pretty-print
-- @param tabs <i>optional, default 0</i>, the level of indentation
-- @param packed <i>optional, default false</i>, if true, minimal spacing is used
function pretty_print(val, --[[Optional]] tabs, --[[Optional]] packed)
    print(pretty_tostring(val, tabs, packed))
end

local function pretty_s(val)
    if type(val) ~= "function" then
        return pretty_tostring_compact(val)
    end
    local info = debug.getinfo(val)
    local ups = "{" ; for i=1,info.nups do 
        local k, v = debug.getupvalue(val,i) ; ups = ups .. k .."="..tostring(v)..","
    end
    return "function " .. info.source .. ":" .. info.linedefined .. "-" .. info.lastlinedefined .. ups .. '}'
end

-- Convenience print-like function:
function pretty(...)
    local args = {}
    for i=1,select("#", ...) do
        args[i] = pretty_s(select(i, ...))
    end
    print(unpack(args))
end

local function prettyPrintAst(ast, indent)
    io.write(indent .. ') ')
    for i=1,indent do io.write(". ") end
    if type(ast) == "table" and rawget(ast, "label") then
        if type(ast.values) == "table" then
            for i=1,#ast.values do
                prettyPrintAst(ast.values[i], indent + 1)
            end
        end
    else pretty(ast) end
end
function prettyAst(...)
    for i in values{...} do prettyPrintAst(i, 1) end
end

local smap = {}
for k,v in pairs(goal) do
    if k:find("SMEMBER_") == 1 then smap[v] = k:sub(#"SMEMBER_" + 1) end
end

function prettyBytecode(bc)
    for i, code in ipairs(bc.Bytecodes) do 
        io.write(i .. ') ')
        local v = code.Code
        if v == goal.BC_CONSTANT then
            print("Constant Push \"" .. tostring(bc.Constants[code.Bytes1to3()+1].Value):gsub("\n", "\\n") .. "\"")
        elseif v == goal.BC_SPECIAL_PUSH then
            print("Special Push '" .. smap[code.Val3] .. "' of ".. code.Bytes1to2())
        elseif v == goal.BC_PUSH then
            print("Stack Push I:" .. code.Bytes1to3())
        elseif v == goal.BC_PUSH_NIL then
            print("Nil Push")
        elseif v == goal.BC_NEXT then
            print("NEXT " .. code.Bytes1to3())
        elseif v == goal.BC_MEMBER_PUSH then
            print("Member Push '" .. goal.TypeInfo.TypeMembers[code.Val3+1] .. "' of " .. code.Bytes1to2())
        elseif v == goal.BC_POPN then
            print("Pop :" .. code.Bytes1to3())
        elseif v == goal.BC_CONCATN then
            print("Concat " .. code.Bytes1to3())
        elseif v == goal.BC_JMP_FALSE then
            print("JumpIfFalse I: " .. code.Bytes1to3())
        elseif v == goal.BC_JMP then
            print("Jump I: " .. code.Bytes1to3())
        elseif v == goal.BC_PRINTFN then
            print("PrintF N: " .. code.Bytes1to3())
        elseif v == goal.BC_BIN_OP then
            local op = code.Bytes1to3()
            if op == goal.BIN_OP_AND then
                print("AND")
            elseif op == goal.BIN_OP_OR then
                print("OR")
            elseif op == goal.BIN_OP_XOR then
                print("XOR")
            elseif op == goal.BIN_OP_TYPECHECK then 
                print("TYPECHECK")
            end
        else 
            print("Unknown code " .. v)
        end
    end
end

function file_as_string(name)
    local f = io.open(name,"r")
    if f == nil then return nil end
    local contents = f:read("*all")
    f:close()
    return contents
end

function newtype(args)
    local get, set = {}, {}
    local parent = args and args.parent
    local type = {get = get, set = set}

    function type.create(...)
        local val = setmetatable({}, type)
        type.init(val, ...)
        return val
    end

    function type:__index(k)
        local getter = get[k]
        if getter then return getter(self, k) end
        local type_val = type[k]
        if type_val then return type_val end
        if parent then
            local idx_fun = parent.__index
            if idx_fun then return idx_fun(self, k) end
        end
        error(("Cannot read '%s', member does not exist!\n"):format(tostring(k)))
    end

    function type:__newindex(k, v)
        local setter = set[k]
        if setter then
            setter(self, k, v)
            return
        end
        if parent then
            local newidx_fun = parent.__newindex
            if newidx_fun then
                newidx_fun(self, k, v)
                return
            end
        end
        rawset(self, k, v)
    end

    return type
end
