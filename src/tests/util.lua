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

-- Convenience print-like function:
function pretty(...)
    local args = {}
    for i=1,select("#", ...) do
        if type(args[i]) == "function" then
            args[i] = pretty_tostring_compact(debug.getinfo(select(i, ...)))
        else
            args[i] = pretty_tostring_compact(select(i, ...))
        end 
    end
    print(unpack(args))
end

