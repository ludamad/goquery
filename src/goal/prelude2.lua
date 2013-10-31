--------------------------------------------------------------------------------
-- Lua configuration, basic configuration of the Lua VM to make life easier.
--------------------------------------------------------------------------------

local type = _G.type -- DSL redefines 'type'
typeof = type -- Alias

-- Keep this around for now, for convenience. Remove for 1.0.
dofile "src/tests/util.lua"

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

local append = table.insert

local function do_nothing() end

local function pack(...)
    local t = {}
    for i=1,select("#", ...) do
        local val = assert(select(i, ...), "Found nil value at ".. i)
        append(t, val)
    end
    return t
end

function table.key_list(t)
    local keys = {}
    for k, _ in pairs(t) do append(keys, k) end
    return keys
end
function table.index_of(t, val)
    for k,v in pairs(t) do if v == val then return k end end
    return nil
end

function values(table)
    local idx = 1
    return function()
        local val = table[idx]
        idx = idx + 1
        return val
    end
end

function appendAll(...)
    local tabs, ret = pack(...), {}
    for tab in values(tabs) do for v in values(tab) do append(ret, v) end end
    return ret
end
function mergeAll(...)
    local ret = {}
    for i=1,select("#", ...) do
        for k, v in pairs(select(i, ...) or {}) do
            assert(not ret[k], "Tables passed to mergeAll are not mutually exclusive!")
            ret[k] = v
        end
    end
    return ret
end
function pairsAll(...) return pairs(mergeAll(...)) end
function ipairsAll(...) return ipairs(appendAll(...)) end
function valuesAll(...) return values(appendAll(...)) end

function string:split(sep)
    local t = {}
    self:gsub(("([^%s]+)"):format(sep), function(s) append(t, s) end)
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
-- Functional operator API
--------------------------------------------------------------------------------

function Map(f,list) 
    local newList = {}
    for v in values(list) do append(newList, v) end
    return newList
end
local function varargMap(f,...) return unpack(Map(f, pack(...))) end
function Compose(f,g) return function(...) 
    return f(g(...))
end end
function Inject(f,g, --[[Optional]] index) return function(...)
    local args = pack(...)
    args[index or 1] = g(args[index or 1])
    return f(unpack(args))
end end
function InjectAll(f,g, --[[Optional]] index) return function(...)
    return f(varargMap(g, ...))
end end

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
    for str in values(strings) do bc.PushStringConstant(str) end
end

function goal.PushBytecodes(bc, bytecodes)
    for code in values(bytecodes) do bc.PushBytecode(code) end
end

goal.DefineTuple = gsym.DefineTuple

--------------------------------------------------------------------------------
-- Stack allocator. Provides efficient allocation of common subobjects.
--------------------------------------------------------------------------------

local ObjectRef = class()
goal.ObjectRef = ObjectRef

function ObjectRef:init(name, --[[Optional]] parent, --[[Optional]] previous)
    self.name = name
    self.parent, self.previous = parent or false, previous or false
    self.members, self.memberMap = {}, {}
    self.allocSize, self.stackIndex = false, false
end

function ObjectRef:Lookup(key)
    local var = self.memberMap[key]
    if not var then
        var = ObjectRef(key, self, self.members[#self.members])
        append(self.members, var)
        self.memberMap[key] = var
    end
    -- Forward along if there are more arguments:
    return var
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
    if self.stackIndex then
        -- Cached, return 
    elseif self.previous then
        self.stackIndex = self.previous.ResolveIndex() + self.previous.ResolveSize()
    elseif self.parent then
        self.stackIndex = self.parent.ResolveIndex() + 1
    else
        self.stackIndex = -1 -- Base case, the root is a pseudo-node
    end
    return self.stackIndex
end

-- Figure out how 'deep' we are, the elements at the end of a given stack frame start at 0
function ObjectRef:ResolveSize()
    if self.allocSize then return self.allocSize end
    self.allocSize = 1
    for m in values(self.members) do
        self.allocSize = self.allocSize + m.ResolveSize()
    end
    return self.allocSize
end

function ObjectRef:__tostring()
    return ("(ObjectRef name=%s parent=%s previous=%s allocSize=%s stackIndex=%s)"):format(
        self.name, tostring(self.parent), tostring(self.previous), tostring(self.allocSize), tostring(self.stackIndex)
    )
end

--------------------------------------------------------------------------------
-- Bytecode compiler
--------------------------------------------------------------------------------

local Compiler = class()
goal.Compiler = Compiler
local NBlock -- defined in next section

function Compiler:init(contextVar, --[[Optional]] bc)
    self.bytes = bc or goal.NewBytecodeContext()
    self.objects = ObjectRef()
    if contextVar then
        self.ResolveObject(contextVar:split("."))
    end
    self.constantIndex = 0
    self.constantMap = {}
    self.code = NBlock()
end

local function numToBytes(num, n)
    local bytes = {}
    for i=1,n do
        append(bytes, num % 256)
        num = math.floor(num / 256)
    end
    return unpack(bytes)
end

function Compiler:Compile123(code, arg, --[[Optional]] idx)
    local b1,b2,b3 = numToBytes(arg, 3)
    if not idx then print("Compiling123 ", code, arg) end
    local bc = goal.Bytecode(goal[code], b1,b2,b3)
    if idx then 
        self.bytes.SetBytecode(idx, bc)
    else 
        self.bytes.PushBytecode(bc)
    end
end
function Compiler:Compile12_3(code, arg1, arg2)
    local b1,b2 = numToBytes(arg1, 2)
    print("Compiling12_3 ", code, arg1, arg2 )
    return self.bytes.PushBytecode(goal.Bytecode(goal[code], b1,b2, arg2))
end
function Compiler:AddNode(node) self.code.Add(node(self)) end 
function Compiler:AddNodeRefs(nodes)
    for n in values(nodes) do self.AddNode(n) end
end
function Compiler:CompileAll() self.code(self) end
function Compiler:CompileConstant(constant)
    assert(type(constant) == "string")
    self.Compile123("BC_STRING_CONSTANT", self.ResolveConstant(constant))
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
function Compiler:CompilePlaceholder() return self.bytes.PushBytecode(goal.Bytecode(0,0,0,0)) end -- Placeholder for jump
function Compiler:BytesSize() return self.bytes.BytecodeSize() end -- Placeholder for jump
function Compiler:ResolveObject(parts)
    local node = self.objects
    if #parts == 0 then
        return nil
    end
    for part in values(parts) do
        assert(part:match("^%w+$"), "Identifiers must be made up of letters only! (got \"" .. table.concat(parts, ".") .. "\")")
        node = node.Lookup(part)
    end
    return node
end
function Compiler:ParseVariable(str)
    local parts = str:split(".")
    local name = parts[#parts] ; parts[#parts] = nil
--    assert(name:match("^%l%w+$"), "Expecting a string reference! (got \"" .. table.concat(parts, ".") .. "\")")
    local obj = self.ResolveObject(parts)
    return obj, name
end

--------------------------------------------------------------------------------
-- Program AST. The basic building blocks of the DSL
--------------------------------------------------------------------------------

NBlock = class()
goal.NBlock = NBlock
function NBlock:init(C, --[[Optional]] block)
    self.block = block or {}
    for i,f in ipairs(self.block) do self.block[i] = f(C) end
end
function NBlock:Add(code) 
    append(self.block, code)
end
local function callNodes(nodes, C)
    assert(C)
    local block = {}
    for i,f in ipairs(nodes) do 
        local fc = f(C)
    append(block, fc) end
     for child in values(block) do
         child(C)
     end
end
function NBlock:__call(C)
    callNodes(self.block, C)
end

ops = {}
function ops.Print(C, str)
    return function()
        C.CompileConstant(str)
        C.Compile123("BC_PRINTFN", 1)
    end
end
function ops.stringPush(C, expression)
    local obj, name = C.ParseVariable(expression)
    local idx = obj and obj.ResolveIndex() or 0
    return function()
        C.Compile12_3("BC_STRING_PUSH", idx, goal["SMEMBER_" .. name])
    end
end
function ops.objectPush(C, expression)
    local obj, name = C.ParseVariable(expression)
    local idx = obj and obj.ResolveIndex() or 0
    return function() 
        C.Compile12_3("BC_OBJECT_PUSH", idx, goal["OMEMBER_" .. name])
    end
end

function ops.checkExists(C, expression, yesCaseNode, noCaseNode)
    return function(C)
        expression(C)
        local jumpToNoCaseStart = C.CompilePlaceholder()
        yesCaseNode(C)
        local jumpToNoCaseEnd = C.CompilePlaceholder()
        local noCaseStart = C.BytesSize()
        noCaseNode(C)
        local noCaseEnd = C.BytesSize()
        C.Compile123("BC_JMP_OBJ_ISNIL", noCaseStart, jumpToNoCaseStart)
        C.Compile123("BC_JMP", noCaseEnd, jumpToNoCaseEnd)
    end
end
function ops.Printf(C, str, ...)
    local args = {...}
    return function(C)
        C.CompileConstant(str)
        callNodes(args, C)
        C.Compile123("BC_PRINTFN", #args + 1)
    end
end


--------------------------------------------------------------------------------
-- Helpers for defining the Goal API functions, which build nodes of the AST
--------------------------------------------------------------------------------
local function nodes2table(nodes)
    local table = {}
    for n in values(nodes) do table[nodes.label] =n end
    return table
end
-- Create a function that simply provides a labelled node
local function makeLabelNode(label)
    return function(...) 
        local args = {...}
        return { label = label, children = args}
    end
end
local function listNode(node) return node.children end
local function valueNode(node, label) 
    assert(#node.children == 1,
        ("'%s' expects %s parameter."):format(label, #node.children < 1 and "a" or "only one")
    )
end
local NodeVisitRules = class()
function NodeVisitRules:init(label, childWalkers, convertListToTable, transformer)
    for sublabel,subtransformer in pairs(childWalkers) do
        if type(subtransformer) == "function" then -- Wrap functions in simple nodes 
            childWalkers[sublabel] = NodeVisitRules(sublabel, {}, false, subtransformer) 
        end
    end
    self.label, self.transformer = label, transformer
    self.childWalkers,self.convertListToTable = childWalkers, convertListToTable
end
function NodeVisitRules:Visit(node)
    if self.label ~= node.label then return end
    local transformedNodes, nodeMap = {}, {}
    for c in values(node.children) do
        for cW in values(self.childWalkers) do
            if self.convertListToTable then
                nodeMap[c.label] = cW.Visit(c)
            else
                append(transformedNodes, cW.Visit(c))
            end
        end
    end
    return self.transformer(self.convertListToTable and nodeMap or transformedNodes, self.label)
end
--------------------------------------------------------------------------------
-- Goal API
--------------------------------------------------------------------------------
local N = NodeVisitRules -- brevity
-- 1) Expression nodes
local expressionNodes = {

}
-- 2) (Non-control) Statement nodes
local statementNodes = {
    

}-- 3) Code conditional nodes
local conditionNodes = {

}-- 4) Code control nodes
local controlNodes = {

}

local allStatementNodes = mergeAll(statementNodes, controlNodes)

-- Root level functions
local roots = {
    N("Analyze", { Files = listNode }, true, 
        function(t)
            ColorPrint("36;1", "-- ANALYZING:\n")
            goal.GlobalSymbolContext.AnalyzeAll(t.Files)
            ColorPrint("36;1", "-- FINISHED ANALYZING.\n")
        end
    ),
    N("Event"), { FuncDecl = valueNode }, true,
        function(t)
            ColorPrint("36;1", "-- ANALYZING:\n")
            goal.GlobalSymbolContext.AnalyzeAll(t.Files)
            ColorPrint("36;1", "-- FINISHED ANALYZING.\n")
        end
    )
}

function Event(...)
    local opts = nodes2map(resolveArgs(pack(...)))
    for k, v in pairs(opts) do
        return function(...)
            local compiler = Compiler(opts[k][1])
            for _, p in ipairs(pack(...)) do 
                table.insert(compiler.code.block, p)
            end
            compiler.CompileAll()
            goal.SetEvent(k, compiler.bytes)
        end
    end
end

local function rootNode()

end
