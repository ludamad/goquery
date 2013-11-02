local type = _G.type -- DSL redefines 'type'

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
        local k, v = debug.getupvalue(val,i) ; ups = ups .. k .."="..pretty_s(v)..","
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
    if type(ast) == "table" and ast.label then
        print(ast.label)
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

function prettyBytecode(bc)
    for i, bc in ipairs(bc.Bytecodes) do 
        io.write(i .. ') ')
        local code = bc.Code
        if code == goal.BC_CONSTANT then
            print("CONSTANT_PUSH \"" .. bc.Constants[code.Bytes1to3()] .. "\"")
        elseif 
    case BC_SPECIAL_PUSH:
        str := bc.resolveStringMember(code.Bytes1to2(), int(code.Val3))
        bc.push(str)
    case BC_MEMBER_PUSH:
        obj := bc.resolveObjectMember(code.Bytes1to2(), int(code.Val3))
        bc.push(obj)
    case BC_POPN:
        bc.popN(code.Bytes1to3())
    case BC_LOOP_PUSH:
        bc.pushLoop(bc.resolveLoop(code.Bytes1to2(), int(code.Val3)))
        bc.tryLoop(false)
    case BC_LOOP_CONTINUE:
        bc.tryLoop(true)
    case BC_CONCATN:
        bc.concatStrings(code.Bytes1to3())
    case BC_SAVE_TUPLE:
        n := int(code.Val3)
        bc.SaveTuple(code.Bytes1to2(), bc.copyStrings(n))
        bc.popN(n)
    case BC_LOAD_TUPLE:
        n := int(code.Val3)
        tuple := bc.LoadTuple(code.Bytes1to2(), bc.copyStrings(n))
        bc.popN(n)
        if len(tuple) == 0 {
            bc.push(nil)
        } else {
            bc.push(tuple)
        }
    case BC_MAKE_TUPLE:
        n := code.Bytes1to3()
        bc.push(bc.copyStrings(n))
        bc.popN(n)
    case BC_JMP_FALSE:
        topVal := bc.peek(1)
        if topVal == nil || topVal == false || topVal == ""  {
            bc.Index = code.Bytes1to3()
        }
        bc.popN(1)
    case BC_BOOL_AND: // Evaluates an object-oriented 'and' of the top two elements, pops both, pushes result
        panic("TODO")
    case BC_BOOL_OR: // Evaluates an object-oriented 'or' of the top two elements, pops both, pushes result
        panic("TODO")
    case BC_BOOL_XOR: // Evaluates a 'xor' of the top two elements, pops both, pushes result
        panic("TODO")
    case BC_BOOL_NOT: // Evaluates a 'not' of the top element, pops it, pushes result
        panic("TODO")
    case BC_JMP:
        bc.Index = code.Bytes1to3()
    case BC_PRINTFN:
        n := code.Bytes1to3()
        bc.printN(n)
    default:
        panic("Bad bytes!")
    }
    end
end