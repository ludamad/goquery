--------------------------------------------------------------------------------
-- Installs a better debug.traceback, with color highlighting and filtered noise.
--------------------------------------------------------------------------------

local AnsiColors -- Lazy imported


-- **Hack:
local function real_path_to_virtual(s) return s end

local PARAM_SPECS = {
    BOLD = ";1",
    FAINT = ";2",
    ITALIC = ";3",
    UNDERLINE = ";4",
    CROSS = ";9",
}

local function resolve_col_and_params(colspec)
    -- Split comma-separated traits
    local traits = colspec:upper():split("_")
    local col,params = "RESET",""
    for t in values(traits) do
        if PARAM_SPECS[t] then params = params .. PARAM_SPECS[t] 
        elseif t ~= '' then col = t end
    end
    return col,params
end

local function colorfmt_aux(sub)
    local colspec,str = sub:match("^%{([%w_]+):(.*)%}$")
    if not colspec then return sub end
    local col, params = resolve_col_and_params(colspec)
    str = AnsiColors[col](str, params)
    str = str:gsub("%b{}", colorfmt_aux)
    return str
end

local function colfmt(str, ...)
    local str = str:gsub("%b{}", colorfmt_aux):format(...) ; return str
end
-- **End hack

local LUAFILE_PATTERN = "%w+/[^%.]*%.lua"
local ROOTFILE_PATTERN = "%w+%.lua"
local LUAMODULE_PATTERN = "[%.%w_]+%.%u%w*"

local function modulestart(s)
    -- Search for space, followed by any root package name.
    return ("%s*%w+/" .. s)
end

local FILE_LINE_MATCHER = modulestart("%s*[^%.]+%.lua:%d+:%s*")

-- Configuration
local M -- Forward declare for inner functions
M = {
    filter_patterns = {
        -- Lines to delete starting with this line and going up
        [modulestart "ErrorReporting%.lua"] = 1,
        [modulestart "GlobalVariableLoader%.lua:.*'__index'"] = 1,
        [modulestart "Globals%.lua:.*'errorf'"] = 2,
        [modulestart "globals/LuaJITReplacements%.lua:.*'__index'"] = 2,
        [modulestart "Main.lua"] = 1,
        [modulestart "TestRunner.lua:[^']+'main'"] = 1,
        ["%s*%[C%]: in function 'error'"] = 4
    },
    
    stacktrace_replacements = {
        {"stack traceback:", function(s) return M.resolve_color("WHITE", s) end},
        {"%[C%]:.*'", function(s) return colfmt("{faint_white:%s}", s) end}
    },
    
    error_replacements = {
--    "^%s*[^%.]+%.lua:%d+:%s*",
        {'^'.. FILE_LINE_MATCHER, function(s) return '' end},
        {'('..FILE_LINE_MATCHER..')(.*)', function(s1,s2) return colfmt("{bold_white:%s}{white:%s}", s1,s2) end}
    },
    
    virtual_paths = true, 
    use_color = true,
    context = 0
}

local function numformat(n)
    return "%3d"
end

local DOT_LINE = "--------------------------------------------------------------------------------"
function M.resolve_context(fpath, line_num, context)
    local file = io.open(fpath, "r");
    local arr = {}
    if not file then 
        return arr
    end
    local i,min_i,max_i = 1,line_num-context,line_num+context
    -- Find lines within [min_i, max_i]
    for line in file:lines() do
        if i == line_num then
            append(arr, colfmt("{bold_blue:  %3d }{bold_blue:%s}", i, line))
        elseif i >= min_i and i <= max_i then
            append(arr, colfmt("{blue:  %3d }{blue:%s}", i, line))
        end
        i = i + 1
    end
--    append(arr, colfmt("{white:%s}", DOT_LINE))
    return arr
end

function M.resolve_color(col, str, params)
    if M.use_color and AnsiColors then return AnsiColors[col](str, params) end
    return str 
    
end
local function resolve_path(path)
    if not M.virtual_paths then return path end
    if path:match(ROOTFILE_PATTERN) then return path end 
    return real_path_to_virtual(path)
end 

local function resolve_replacements(str, replacements)
    for _,r in ipairs(replacements) do
        str = str:gsub(r[1], r[2])
    end
    return str
end

local function resolve_deletions(stacktrace, i)
    -- We exit immediately if we meet a filter pattern
    for pattern,amount in pairs(M.filter_patterns) do
        if stacktrace[i]:find(pattern) == 1 then
            local delete = math.min(i, amount)
            local index = i - delete + 1
            for j=1,delete do table.remove(stacktrace, index) end
            return delete
        end
    end
    return 0
end

local function resolve_changes(stacktrace, i)
    stacktrace[i] = resolve_replacements(stacktrace[i], M.stacktrace_replacements)

    local inserts = 0
    local converted = {}
    local function path_conv(path, line)
        if M.virtual_paths then 
                append(converted, colfmt("{faint_white:(%s:%s)}", path, line))
                end
        local ret = colfmt("{white:%s:%s}", resolve_path(path), line)
        if M.context > 0 and #converted == 1 then
            local lines = M.resolve_context(path, tonumber(line), M.context, i)
            inserts = #lines
            -- Add context lines
            for j=1,#lines do table.insert(stacktrace, j + i, lines[j]) end
        end
        return ret
    end
    local s = stacktrace[i]
    s = s:gsub('[%<%>]', '')
    s = s:gsub('('..LUAFILE_PATTERN .. "):(%d+)", path_conv)
    s = s:gsub('('..ROOTFILE_PATTERN .. "):(%d+)", path_conv)
    if #converted > 0 then
        s = s .. ' ' .. converted[1]
    end
    stacktrace[i] = s -- Repack value
    return inserts
end

local debug_traceback = debug.traceback -- Stash & wrap the current debug.traceback
-- Improve the traceback in various ways, including adding color and reducing noise:
function M.traceback(--[[Optional]] str)
    local traceback = debug_traceback()
    local stacktrace = traceback:split('\n')
    local i = 1
    while i <= #stacktrace do
        i = i + 1 - resolve_deletions(stacktrace, i)
    end
    for i=1,#stacktrace do
        stacktrace[i] = colfmt('{red:%d} %s', i, stacktrace[i]:trim())
    end
    i = 1
    while i <= #stacktrace do
        i = i + 1 + resolve_changes(stacktrace, i)
    end
    return colfmt(
        "{bold_red:An error occurred:}\n{bold_white:@} {reset:%s}\n%s", 
        resolve_replacements(str or "", M.error_replacements):trim(),
        table.concat(stacktrace, '\n')
    )
end

AnsiColors = require "AnsiColors" -- Lazy import
debug.traceback = M.traceback

return M
