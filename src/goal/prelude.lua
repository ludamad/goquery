--------------------------------------------------------------------------------
-- Lua configuration, basic configuration of the Lua VM to make life easier.
--------------------------------------------------------------------------------

-- Simple type system:
function class()
    local type = {}
    setmetatable(type, {
        __call = function(self, ...)
            local val = setmetatable({}, type)
            type.init(val, ...)
            return val
        end
    })
    function type:__index(k)
        if type[k] then
            local closure = function(...) return type[k](self, ...) end
            self[k] = closure -- Cache it for next time
            return closure
        end
        error(("Class object '%s': Cannot read '%s', member does not exist!\n"):format(tostring(self), tostring(k)))
    end
    return type
end

function string:split(sep)
    local t = {}
    self:gsub(("([^%s]+)"):format(sep), function(s) table.insert(t, s) end)
    return t
end

-- Forbid access to undefined globals
setmetatable(_G, {__index = function(self, k)
    error( ("Global variable '%s' does not exist!"):format(k) )
end})

-- Forbid access to undefined API variables
setmetatable(goal, {__index = function(self, k)
    error( ("'goal.%s' does not exist!"):format(k) )
end})

--------------------------------------------------------------------------------
-- Utility methods and global context
--------------------------------------------------------------------------------

local gsym = goal.NewGlobalContext()
goal.GlobalSymbolContext = gsym
local events = gsym.Events

-- Find all bytecodes, and expose global helpers:
for k, v in pairs(goal) do
    if k:find("BC_") == 1 then
        _G[k:sub(4)] = function(b1,b2,b3,b4)
            return goal.Bytecode(v, b1 or 0, b2 or 0, b3 or 0, b4 or 0)
        end 
    end
end

-- For testing purposes:
function goal.SimpleBytecodeContext(constants, bytecodes)
    local bc = goal.NewBytecodeContext()
    goal.PushConstants(bc, constants)
    goal.PushBytecodes(bc, bytecodes)
    return bc
end

function goal.SimpleRun(constants, bytecodes) 
    local bc = goal.SimpleBytecodeContext(constants, bytecodes)
    bc.Exec(goal.GlobalSymbolContext, goal.NullFileContext, {})
end

function goal.SetEvent(type, ev)
    events[type] = ev
end

function goal.SetTypeSpecEvent(type, ev)
    events.TypeSpecEvents[type] = ev
end

function goal.PushConstants(bc, strings)
    for _, str in ipairs(strings) do bc.PushStringConstant(str) end
end

function goal.PushBytecodes(bc, bytecodes)
    for _, code in ipairs(bytecodes) do bc.PushBytecode(code) end
end

goal.DefineTuple = gsym.DefineTuple

--------------------------------------------------------------------------------
-- Bytecode compiler
--------------------------------------------------------------------------------

local ObjectRef = class()
goal.ObjectRef = ObjectRef

function ObjectRef:init(name, --[[Optional]] parent, --[[Optional]] previous)
    self.name = name
    self.parent, self.previous = parent or false, previous or false
    self.members, self.memberMap = {}, {}
    self.allocSize, self.stackIndex = false, false
end

function ObjectRef:Lookup(key, ...)
    local var = self.memberMap[key]
    if not var then
        var = ObjectRef(key, self, self.members[#self.members])
        table.insert(self.members, var)
        self.memberMap[key] = var
    end
    -- Forward along if there are more arguments:
    return (...) and var.Lookup(...) or var
end

-- Only makes sense on root object ref, aka the stack
function ObjectRef:Pop(n)
    local len = #self.members
    for i = len, len - n + 1, -1 do
        local name = self.members[i].name
        self.memberMap[name] = nil
        self.members[i] = nil -- Pop value
    end
end

function ObjectRef:ResolveIndex()
    if self.stackIndex then return self.stackIndex end
    if self.previous then
        return self.previous.ResolveIndex() + self.previous.ResolveSize()
    elseif self.parent then
        return self.parent.ResolveIndex() + 1
    else
        return -1 -- Base case, the root is a pseudo-node
    end
end

-- Figure out how 'deep' we are, the elements at the end of a given stack frame start at 0
function ObjectRef:ResolveSize()
    if self.allocSize then return self.allocSize end
    self.allocSize = 1
    for _, m in ipairs(self.members) do
        self.allocSize = self.allocSize + m.ResolveSize()
    end
    return self.allocSize
end

function ObjectRef:__tostring()
    return ("(ObjectRef name=%s parent=%s previous=%s allocSize=%s stackIndex=%s)"):format(
        self.name, tostring(self.parent), tostring(self.previous), tostring(self.allocSize), tostring(self.stackIndex)
    )
end

-- Program AST
local NBlock = class()
goal.NBlock = NBlock
function NBlock:init()
    self.block = {}
end
function NBlock:Add(code) 
    table.insert(self.block, code)
end
function NBlock:__call(C)
    for _, child in ipairs(self.block) do child(C) end
end

local ops = {}
function ops.Print(C, str)
    local idx = C.ResolveConstant(str)
    return function()
        C.CompileConstant(str)
        C.Compile123("BC_PRINTFN", 1)
    end
end

local Compiler = class()
goal.Compiler = Compiler

function Compiler:init(--[[Optional]] bc)
    self.bytes = bc or goal.NewBytecodeContext()
    self.objects = ObjectRef()
    self.constantIndex = 0
    self.constantMap = {}
    self.code = NBlock()
end

dofile "src/tests/util.lua"

local function numToBytes(num, n)
    local bytes = {}
    for i=1,n do
        table.insert(bytes, num % 256)
        num = math.floor(num / 256)
    end
    return unpack(bytes)
end

function Compiler:Compile123(code, arg)
    local b1,b2,b3 = numToBytes(arg, 3)
    return self.bytes.PushBytecode(goal.Bytecode(goal[code], b1,b2,b3))
end

function Compiler:Compile12_3(code, arg1, arg2)
    local b1,b2 = numToBytes(arg1, 2)
    return self.bytes.PushBytecode(goal.Bytecode(goal[code], b1,b2, arg2))
end

function Compiler:CompileAll()
    self.code(self)
end

function Compiler:CompileConstant(constant)
    self.Compile123("BC_STRING_CONSTANT", self.ResolveConstant(constant))
end

function Compiler:CompileVar(object, var)
    self.Compile12_3("BC_OBJECT_PUSH", var.ResolveIndex(), goal["SMEMBER_" + var])
end

function Compiler:ResolveConstant(constant)
    local index = self.constantMap[constant]
    if not index then
        index = self.constantIndex
        self.constantMap[constant] = index
        self.bytes.PushStringConstant(constant)
        self.constantIndex = self.constantIndex + 1
    end
    return index
end

function Compiler:ResolveString(parts)
    local parts = name:split(".")
end
function Compiler:ResolveObject(parts)
    local node = self.objects
    for _, part in pairs(parts) do
        assert(part:match("^%w+$"), "Identifiers must be made up of letters only! (got \"" .. table.concat(parts, ".") .. "\")")
        node = node.Lookup(part)
    end
    return node
end

--------------------------------------------------------------------------------
-- Goal API
--------------------------------------------------------------------------------
for k,v in pairs(ops) do
    _G[k] = function(...)
        local args = {...}
        return function(compiler)
            return ops[k](compiler, unpack(args))
        end
    end
end

local events = {"FuncDecl"}
for _,k in ipairs(events) do
    _G[k] = function(name) return k, name end
end

function Event(type, name)
    return function(...)
        local compiler = Compiler()
        local nodes = {...} 
        for _,node in ipairs(nodes) do
            compiler.code.Add(node(compiler))
        end
        compiler.CompileAll()
        goal.SetEvent(type, compiler.bytes)
    end
end

function AnalyzeAll(fnames)
    ColorPrint("36;1", "-- ANALYZING:\n")
    goal.GlobalSymbolContext.AnalyzeAll(fnames)
    ColorPrint("36;1", "-- FINISHED ANALYZING.\n")
end