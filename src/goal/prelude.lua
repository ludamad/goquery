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
 -- This works because pairs returns (next, k)
table.next, _ = pairs {}

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
function Curry(f,x, --[[Optional]] index) return function(...)
    local args = pack(...)
    table.insert(args, index or 1, x)
    return f(unpack(args))
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
    local obj = self.ResolveObject(parts)
    return obj, name
end

function goal.Compile(varname, code)
    pretty(varname, code)
    local c = Compiler(varname)
    for n in values(code) do c.code.Add(n) end
    return c.bytes
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

function ops.Printf(C, str, ...)
    local args = {...}
    return function(C)
        C.CompileConstant(str)
        callNodes(args, C)
        C.Compile123("BC_PRINTFN", #args + 1)
    end
end

local exprs = {}
function exprs.Var(var)
    local parts = var:split(".")
    local isString = parts[#parts]:match("^%l")
    -- Choose with value pushed to use:
    return Curry((isString and exprs.stringPush or exprs.objectPush), var, 2)
end

-- Makes the AST nodes that form expressions look kind-of like lua refs:
local VarBuilder = class()
function VarBuilder:init(repr) self.repr = repr end
function VarBuilder:__index(k) return VarBuilder(self.repr .. '.' .. k) end
function VarBuilder:__call(k)
    if type(k) == "string" then return exprs.Var(k .. "." .. self.repr) end
    return exprs.Var(self.repr .. k.repr)
end

for k,v in pairs(goal) do
    if k:find("SMEMBER_") == 1 or k:find("OMEMBER_") == 1 then 
        k = k:sub(#"MEMBER_" + 2)
        _G[k] = VarBuilder(k)
    end
end

--------------------------------------------------------------------------------
-- Helpers for defining the Goal API functions, which build nodes of the AST
--------------------------------------------------------------------------------
local function nodes2table(nodes)
    local table = {}
    for n in values(nodes) do table[nodes.label] =n.values end
    return table
end
-- Create a function that simply provides a labelled node
local function makeLabelNode(label, values) return { label = label, values = values} end
local function simpleNode(label, ...) return makeLabelNode(label, pack(...)) end
local function listNode(node) return node.values end
local function valueNode(node) 
    assert(#node.values == 1, ("'%s' expects %s parameter."):format(node.label, #node.values < 1 and "a" or "only one"))
    return node.values[1]
end
local NodeTransformer = class()
function NodeTransformer:init(label, childWalkers, convertListToTable, transformer)
    self.childWalkers = childWalkers and {} or false
    if childWalkers then
        for sublabel,subtransformer in pairs(childWalkers or {}) do
            if type(subtransformer) == "function" then -- Wrap functions in simple nodes 
                append(self.childWalkers, NodeTransformer(sublabel, nil, false, subtransformer)) 
            else append(self.childWalkers, subtransformer) end
        end
    end
    self.label, self.transformer = label, transformer
    self.convertListToTable = convertListToTable
end
function NodeTransformer:Apply(labelNode)
    if not self.childWalkers then -- Simple case 
        return self.transformer(labelNode) 
    end
    -- Complex case
    local transformedNodes, nodeMap = {}, {}
    for c in values(labelNode.values) do
        for cW in values(self.childWalkers) do
            if cW.label ~= c.label then
                -- Nothing
            elseif self.convertListToTable then
                nodeMap[c.label] = cW.Apply(c)
            else
                append(transformedNodes, cW.Apply(c))
            end
        end
    end
    local value = (self.convertListToTable and nodeMap or transformedNodes)
    return self.transformer(makeLabelNode(self.label, value))
end
function NodeTransformer:AllLabelValues(--[[Optional]] t)
    t = t or {}
    for c in values(self.childWalkers or {}) do append(t, c.label) ; c.AllLabelValues(t) end
    return values(t)
end
function NodeTransformer:__call(...)
    return self.Apply(simpleNode(self.label, ...))
end
--------------------------------------------------------------------------------
-- Goal API
--------------------------------------------------------------------------------

local NT = NodeTransformer -- brevity

local opNodes -- All the statement nodes possible

local function codeNodeTransform(node) return function(C) 
    assert(opNodes[node.label], ("'%s' is not a valid code node!"):format(node.label))
    return opNodes[node.label](C, unpack(node.values))
end end

local function makeExpr(...) 
    assert(select('#',...) == 1)
    local ex = ... ; return function(C) pretty(ex) ; return exprs[ex.label](C, unpack(ex.values)) end 
end

local function makeCodeBlock(...)
    return Map(codeNodeTransform, pack(...))
end

-- Less easy to define operators:
local specialOps = {
    NT("CheckExists", { Expr = makeExpr, Yes = makeCodeBlock, No = makeCodeBlock }, true, 
        function(t)
            pretty("CheckExists",t)
         return function(C)
            pretty(t)
            t.values.Expr(C)
            local jumpToNoCaseStart = C.CompilePlaceholder()
            yesCaseNode(C)
            local jumpToNoCaseEnd = C.CompilePlaceholder()
            local noCaseStart = C.BytesSize()
            noCaseNode(C)
            local noCaseEnd = C.BytesSize()
            C.Compile123("BC_JMP_OBJ_ISNIL", noCaseStart, jumpToNoCaseStart)
            C.Compile123("BC_JMP", noCaseEnd, jumpToNoCaseEnd)
        end end
    )
}

opNodes = mergeAll(ops)
for op in values(specialOps) do opNodes[op.label] = op end

-- Root level functions
local roots = {
    NT("Analyze", { Files = listNode }, true, 
        function(t)
            ColorPrint("36;1", "-- ANALYZING:\n")
            goal.GlobalSymbolContext.AnalyzeAll(t.values.Files)
            ColorPrint("36;1", "-- FINISHED ANALYZING.\n")
        end
    ),
    NT("Event", { FuncDecl = valueNode }, true,
        function(t)
            local event, varName = table.next(t.values) -- Find first
            return function(...) goal.SetEvent(event, goal.Compile(varName, makeCodeBlock(...))) end
        end
    )
}
-- Expose API
for nt in valuesAll(roots, specialOps) do 
    for label in nt.AllLabelValues() do
        _G[label] = Curry(simpleNode, label) 
    end
end
for root in values(roots) do _G[root.label] = root end
for label,v in pairsAll(opNodes, exprs) do
    _G[label] = Curry(simpleNode, label)
end