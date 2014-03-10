--------------------------------------------------------------------------------
-- Various globals, defined for convenience
--------------------------------------------------------------------------------

local type = _G.type -- DSL redefines 'type'
_G.typeof = type
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

--------------------------------------------------------------------------------
-- Lua configuration, basic configuration of the Lua VM to make life easier.
--------------------------------------------------------------------------------

-- Simple type system:

function class(--[[Optional]] name)
    local type = {name = name}
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
        error(("'%s': Cannot read '%s', member does not exist!\n"):format(tostring(self), tostring(k)))
    end
    function type:__tostring() -- Default
        if type.name then return ("(Class %s)"):format(type.name) end
        local srcInfo = debug.getinfo(type.init) ; return ("(Class %s:%s)"):format(srcInfo.source, srcInfo.linedefined)
    end
    return type
end

local function assertAll(...) for v in values {...} do assert(v) end end
local append = table.insert

local function softAppend(t,v) if v then append(t,v) end end
 -- This works because pairs returns (next, k)

local function do_nothing() end

local function pack(...)
    local t = {}
    for i=1,select("#", ...) do
        local val = select(i, ...) ; assert(val ~= nil, "Found nil value at ".. i) ; append(t, val)
    end
    return t
end


function appendAll(...)
    local tabs, ret = pack(...), {}
    for tab in values(tabs) do for v in values(tab) do append(ret, v) end end
    return ret
end

local function mergeAllMake(overwriting) return function(...)
    local ret = {}
    for i=1,select("#", ...) do
        for k, v in pairs(select(i, ...) or {}) do
            if not overwriting then assert(not ret[k], "Tables passed to mergeAll are not mutually exclusive, share " .. k .. "!") end
            ret[k] = v
        end
    end
    return ret
end end
mergeAll,mergeAllOverwriting = mergeAllMake(false),mergeAllMake(true)

function pairsAll(...) return pairs(mergeAll(...)) end

function pairsAllOverwriting(...) return pairs(mergeAllOverwriting(...)) end

function ipairsAll(...) return ipairs(appendAll(...)) end

function valuesAll(...) return values(appendAll(...)) end

-- Forbid access to undefined globals
setmetatable(_G, {__index = function(self, k) error( ("Global variable '%s' does not exist!"):format(k) ) end})

-- Forbid access to undefined API variables
setmetatable(goal, {__index = function(self, k) error( ("'goal.%s' does not exist!"):format(k) ) end})

--------------------------------------------------------------------------------
-- Functional operator API
--------------------------------------------------------------------------------

function Map(f,list) 
    local newList = {} ; for v in values(list) do softAppend(newList, f(v)) end ; return newList
end

local function mapValues(f, list) return values(Map(f, list)) end

local function varargMap(f,...) return unpack(Map(f, pack(...))) end

function Compose(f,g) return function(...) 
    return f(g(...))
end end

function Curry(f,x, --[[Optional]] index) assert(f and x) ; return function(...)
    local args = pack(...)
    table.insert(args, index or 1, x)
    return f(unpack(args))
end end

function Inject(f,g, --[[Optional]] index) assert(f and g) ; return function(...)
    local args = pack(...)
    args[index or 1] = g(args[index or 1])
    return f(unpack(args))
end end

function InjectAll(f,g, --[[Optional]] index) assert(f and g) ; return function(...)
    return f(varargMap(g, ...))
end end

--------------------------------------------------------------------------------
-- Utility methods and global context
--------------------------------------------------------------------------------
local gsym = goal.NewGlobalContext() ; goal.GlobalSymbolContext = gsym
local events = gsym.Events

-- Find all bytecodes, and expose global helpers:
for k, v in pairs(goal) do
    if k:find("BC_") == 1 then
        _G[k:sub(4)] = function(b1,b2,b3,b4)
            return goal.Bytecode(v, b1 or 0, b2 or 0, b3 or 0, b4 or 0)
        end 
    end
end

-- Expose a function as part of the GoAL API:
function goal.API(k, f) 
    -- Avoid  names not intended to be exported:
    if k ~= "string" and k ~= "int" then
        _G[k] = f 
    end
end

function goal.SliceToTable(slice)
    local ret = {}
    for i=1,#slice do
        ret[i] = slice[i]
    end
    return ret
end

local function sliceWrap(f) 
    return function(...) return goal.SliceToTable(f(...)) end
end

for toWrap in values {"FindSubdirectories"} do
    goal[toWrap] = sliceWrap(goal[toWrap])
end

function goal.ListMethods()
    local methods = {}
    for k,v in pairs(_G) do
        if k:match("%u") then
            append(methods, k)
        end
    end 
    table.sort(methods)
    for method in values(methods) do
        print(method)
    end
end

-- For testing purposes:

function goal.SimpleBytecodeContext(constants, bytecodes) local bc = goal.NewBytecodeContext() ; goal.PushConstants(bc, constants) ; goal.PushBytecodes(bc, bytecodes) ;return bc end

function goal.SimpleRun(constants, bytecodes) 
    local bc = goal.SimpleBytecodeContext(constants, bytecodes)
    prettyBytecode(bc)
    bc.ExecNoParent(goal.GlobalSymbolContext, goal.NullFileContext, goal.NewObjectStack()) 
end

function goal.PushEvent(type, ev) events.PushEvent(goal.TypeInfo.NameToType[type], ev) end

function goal.PushConstants(bc, strings) for str in values(strings) do bc.PushConstant(str) end end

function goal.PushBytecodes(bc, bytecodes) for code in values(bytecodes) do bc.PushBytecode(code) end end

-- Members on a global object -> promote to global functions for convenience:
for k in values {"DefineData", "SchemaFromName", "OpenConnection", "CloseConnection", "Commit", "Query"} do goal[k] = gsym[k] end

--------------------------------------------------------------------------------
-- Stack allocation helpers. Provide efficient allocation of common subobjects.
--------------------------------------------------------------------------------
local StackAllocator = class "StackAllocator" ; goal.StackAllocator = StackAllocator

function StackAllocator:init() self.I = 0 ; self.unresolved = {} end

function StackAllocator:Increment() self.I = self.I + 1 ; return self.I - 1 end

function StackAllocator:Enqueue(obj) append(self.unresolved, obj) end

function StackAllocator:Reset(I) self.I = I or 0 end
local ObjectRef = class "ObjectRef" ; goal.ObjectRef = ObjectRef

function ObjectRef:init(allocator, name, --[[Optional]] parent, --[[Optional]] previous)
    self.allocator,self.name = allocator, name ; self.members, self.memberMap = {}, {}
    assert(type(self.name) == "string")
    self.parent, self.previous = parent or false, previous or false
    self.queued, self.allocSize, self.stackIndex = false, false, false
end

function ObjectRef:QueueForAlloc() if self.queued then return end
    if self.previous then self.previous.QueueForAlloc() elseif self.parent then self.parent.QueueForAlloc() end
    if self.parent then self.allocator.Enqueue(self) ; self.queued = true end 
end

function ObjectRef:Create(key) assert(not self.memberMap[key])
    local var = ObjectRef(self.allocator, key, self, self.members[#self.members]) ; append(self.members, var) ; 
    if key ~= "" then assert(not self.memberMap[key], ("Variable '%s' already exists!"):format(key)) end 
    self.memberMap[key] = var ; return var
end

function ObjectRef:Lookup(key, --[[Optiona]] dontCreate)
    local m = self.memberMap[key]; if m then return m end ; if dontCreate then assert(false,key) end return self.Create(key)
end

function ObjectRef:AllocateIndex() if self.stackIndex then return self.stackIndex end -- Already resolved, return
    if self.previous then self.previous.AllocateIndex() ; self.stackIndex = self.allocator.Increment(self)
    elseif self.parent then self.parent.AllocateIndex() ; self.stackIndex = self.allocator.Increment(self) 
    else self.stackIndex = -1 end ; return self.stackIndex
end

-- Figure out how 'deep' we are, the elements at the end of a given stack frame start at 0

function ObjectRef:ResolveSize()
    if self.allocSize then return self.allocSize end
    self.allocSize = 1 ; for m in values(self.members) do
        self.allocSize = self.allocSize + m.ResolveSize()
    end ; return self.allocSize
end

function ObjectRef:RootName() return (self.parent.name=="") and self.name or self.parent.RootName() end

function ObjectRef:__tostring()
    return ("(ObjectRef name=%s parent=%s previous=%s allocSize=%s stackIndex=%s)"):format(
        self.name, tostring(self.parent), tostring(self.previous), tostring(self.allocSize), tostring(self.stackIndex)
    )
end

--------------------------------------------------------------------------------
-- Bytecode compiler
--------------------------------------------------------------------------------
local Compiler = class "Compiler" ; goal.Compiler = Compiler
local NBlock -- defined in next section

function Compiler:init(--[[Optional]] contextVar)
    self.allocator = StackAllocator(); self.bytes = goal.NewBytecodeContext() ; self.objects = ObjectRef(self.allocator, "")
    self.constantIndex = 0 ; self.constantMap = {} ; self.nodes = NBlock()
    if contextVar then self.AddVariableRoot(contextVar) end
end

local function numToBytes(num, n)
    local bytes = {} ; for i=1,n do append(bytes, num % 256) ; num = math.floor(num / 256) end ; return unpack(bytes)
end

function Compiler:Compile123(code, arg, --[[Optional]] idx)
    local b1,b2,b3 = numToBytes(arg, 3)
    local bc = goal.Bytecode(goal[code], b1,b2,b3)
    if idx then 
        self.bytes.SetBytecode(idx, bc) ; return idx
    else 
        return self.bytes.PushBytecode(bc)
    end
end
Compiler.Recompile123 = Compiler.Compile123 -- Self-documenting alias 

function Compiler:Compile12_3(code, arg1, arg2)
    local b1,b2 = numToBytes(arg1, 2)
    return self.bytes.PushBytecode(goal.Bytecode(goal[code], b1,b2, arg2))
end

local varIds = {}
for i=1,#goal.TypeInfo.TypeMembers do varIds[goal.TypeInfo.TypeMembers[i]] = i-1 end

local function compileObjPushes(C, objs)
    for obj in values(objs) do if obj.RootName() ~= obj.name then
        local isSpecial, idx = obj.name:match("^%l"), obj.AllocateIndex()
        local ref = isSpecial and goal["SMEMBER_".. obj.name] or varIds[obj.name]  
        C.Compile12_3(isSpecial and "BC_SPECIAL_PUSH" or "BC_MEMBER_PUSH", obj.parent.AllocateIndex(), ref)
    end end ; return #objs
end

 -- Compilation occurs in two passes, the first pass returns a function that performs the second pass

function Compiler:CompileAll() 
    local nextPass = self.nodes(self)
    local N = compileObjPushes(self, self.PopVariableRoots(1))
    nextPass(self)
    if N > 1 then self.Compile123("BC_POPN", N - 1) end
end

function Compiler:AddNodes(nodes) self.nodes.AddAll(nodes) end

function Compiler:CompileConstant(constant)
    assert(type(constant) ~= "table") ; self.Compile123("BC_CONSTANT", self.ResolveConstant(constant))
end

function Compiler:ResolveConstant(constant)
    local index = self.constantMap[constant]
    if not index then
        index = self.constantIndex
        self.constantMap[constant] = index
        if type(constant) == "number" then
            self.bytes.PushConstantI(constant)
        else 
            self.bytes.PushConstant(constant)
        end
        self.constantIndex = self.constantIndex + 1
    end
    return index
end

function Compiler:CompilePlaceholder() return self.bytes.PushBytecode(goal.Bytecode(0,0,0,0)) end -- Placeholder for jump

function Compiler:BytesSize() return self.bytes.BytecodeSize() end -- Placeholder for jump

function Compiler:AddVariableRoot(name) return self.objects.Create(name) end

function Compiler:PopVariableRoots(N)
    local O,toBeResolved,stillUnresolved,names=self.objects,{},{},{}
    for i=1,N do
        local m,M=O.members,O.memberMap ; local r=m[#m] ; m[#m]=nil ; M[r.name]=nil
        append(names,r.name)
    end 
    for obj in values(self.allocator.unresolved) do 
        append((table.index_of(names, obj.RootName()) ~= nil) and toBeResolved or stillUnresolved, obj)
    end
    self.allocator.unresolved = stillUnresolved ; return toBeResolved
end

function Compiler:ResolveObject(parts)
    local node, mustExist = self.objects, true
    if #parts == 0 then return nil end
    for part in values(parts) do
        assert(part:match("^%w+$"), "Identifiers must be made up of letters only! (got \"" .. table.concat(parts, ".") .. "\")")
        node = node.Lookup(part, mustExist) ; mustExist = false
    end
    return node
end

function Compiler:ResolveObjectRef(str)
    local parts = str:split(".")
    local obj, name = self.ResolveObject(parts), parts[#parts]
    -- First pass: Push all submembers onto stack
    obj.QueueForAlloc()
    return function() self.Compile123("BC_PUSH", obj.AllocateIndex()) end
end


function goal.Compile(nodes, --[[Optional]] varname)
    local C = Compiler(varname) ; C.AddNodes(nodes) ; C.CompileAll() ; 
    return C.bytes
end

---------------------------------------------------------------------------------
-- Helpers for defining types of nodes
---------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------
-- NodeTransformer: The main utility that transforms label-nodes into 
-- code-emitting AST components.
---------------------------------------------------------------------------------
local NodeTransformer = class "NodeTransformer"

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

function NodeTransformer:Apply(labelNode, --[[Optional]] compiler)
    if not self.childWalkers then return self.transformer(labelNode) end
    -- Complex case
    local transformedNodes, nodeMap = {}, {}
    for c in values(labelNode.values) do
        local converted = false
        for cW in values(self.childWalkers) do
            if cW.label == c.label then
                if self.convertListToTable then nodeMap[c.label] = cW.Apply(c) else append(transformedNodes, cW.Apply(c)) end
                converted = true ; break
            end
        end
        assert(converted, ("The label-node '%s' is not valid inside '%s!'"):format(tostring(c.label), tostring(self.label)))
    end
    local value = (self.convertListToTable and nodeMap or transformedNodes)
    return self.transformer(makeLabelNode(self.label, value), --[[Optional]] compiler)
end

function NodeTransformer:AllLabelValues(--[[Optional]] t)
    t = t or {} 
    for c in values(self.childWalkers or {}) do 
        append(t, c.label) 
        c.AllLabelValues(t) 
    end
    return values(t)
end

function NodeTransformer:__call(...) return self.Apply(simpleNode(self.label, ...)) end

--------------------------------------------------------------------------------
-- Goal API and Program AST components. 
-- The AST components emit code, and are created from the 
-- label-nodes of the GoAL program-tree. 
-- 
-- The root functions of the GoAL API are responsible for collecting a tree
-- of label-nodes and operating on them. Almost all other exposed API functions
-- simply create a tree of label nodes (when called together).
--------------------------------------------------------------------------------

-- Code block creation:
NBlock = class "NBlock" ; goal.NBlock = NBlock-- A linear block of code nodes

function NBlock:init(--[[Optional]] block) self.block = block or {} end

function NBlock:Add(node) append(self.block, assert(node)) end

function NBlock:AddAll(nodes) Map(self.Add, nodes) end

local function resolvePass(C, nodes, --[[Optional]] dontExpectRet)
    local args = {} ; for f in values(nodes) do
        local val = f(C)
        if dontExpectRet and val then
            pretty(f) ; error("Node tried to return a third pass!")
        elseif not dontExpectRet and not val then 
            pretty(f) ; error("Node did not return second pass!")
        end ; append(args, val) 
    end ; return args
end

-- Compiler comes in two passes -- resolve both using Map:
function NBlock:__call(C)  
    local nextBlock = resolvePass(C, self.block) ; return function() resolvePass(C, nextBlock, true) end
end
 -- Holder of all possible statement nodes:
local SNodes = {} ; goal.SNodes = SNodes
 -- Holder of all possible expression nodes:
local ENodes = {} ; goal.ENodes = ENodes

-- Create an AST node from a label-node using a given transformation table:

local function nodeTransform(nodeTable, lnode) if type(lnode) == "function" then pretty(debug.getinfo(lnode)) end ; assert(lnode.label and lnode.values) ; 
    return function(C) 
        assert(nodeTable[lnode.label], ("'%s' is not a valid code node!"):format(lnode.label))
        return nodeTable[lnode.label](C, unpack(lnode.values))
end end

-- Create an AST node from a list of label-nodes using SNodes:

function goal.CodeParse(...) return Map(Curry(nodeTransform, SNodes), pack(...)) end

function goal.CodeBlock(...) return NBlock(goal.CodeParse(...)) end

-- Create an AST node from a label-node using SNodes:

local function constant(val) return function(C) return function() C.CompileConstant(val) end end end

function goal.ExprParse(node) 
    if type(node) == "string" or type(node) == "number" then return constant(node) 
    else return nodeTransform(ENodes, node) end 
end

function goal.ExpressionsParse(...) return Map(goal.ExprParse, pack(...)) end

-- Program AST basic statements:
local basic = {} ; goal.BasicSNodes = basic -- Basic statements

function basic.Print(C, str)
    return function() C.CompileConstant(str) ; C.Compile123("BC_PRINTFN", 1) end
end

function basic.Printf(C, str, ...)
    local args = goal.ExpressionsParse(...) ; local n = #args+1
    args = resolvePass(C, args)
    return function() C.CompileConstant(str) ; resolvePass(C, args, true) ; C.Compile123("BC_PRINTFN", n) end
end

function goal.CallableNode(labelNode, f)
    return setmetatable(makeLabelNode(labelNode.label, labelNode.values), {__call = function(self, ...) return f(...) end })
end

function SNodes.Case(C, cases) 
    -- First pass:
    for case in values(cases) do case[1] = case[1](C) ; case[2] = case[2](C) end
    return function() -- Second pass:
        local endJumps = {} -- Collect all jumps that lead to end
        for case in values(cases) do
            case[1]() ; local condCheck = C.CompilePlaceholder() -- Condition
            case[2]() ; append(endJumps, C.CompilePlaceholder()) -- Block
            C.Recompile123("BC_JMP_FALSE", --[[End]] C.BytesSize(), condCheck)
        end ; for jumpIdx in values(endJumps) do C.Compile123("BC_JMP", --[[End]] C.BytesSize(), jumpIdx) end
    end
end

function Case(expr)
    local cases = {} ; local addCondition, addStatements, finish
    function addCondition(cond) append(cases, {goal.ExprParse(cond)}) ; return addStatements end
    function addStatements(...) 
        cases[#cases][2] = goal.CodeBlock(...) ; return goal.CallableNode(makeLabelNode("Case", {cases}), addCondition)
    end
    return addCondition(expr)
end

function SNodes.Store(C, schemaName, values)
    local nextPass = resolvePass(C, values)
    return function() local schema = goal.SchemaFromName(schemaName)
        local got, expected = #values, schema.FieldLength()
        assert(got == expected, "Wrong argument number to Store! Got " ..  got .. " wanted " .. expected)
        resolvePass(C, nextPass, true)
        C.Compile12_3("BC_SAVE_TUPLE", schema.Id, schema.FieldLength())
    end
end

function Return(value) return function(...)
    return simpleNode("Return")
end end

function Store(schemaName) return function(...)
    return simpleNode("Store", schemaName, goal.ExpressionsParse(...))
end end

function SNodes.ForPairs(C, keyName, valueName, loopable, body)
    loopable = loopable(C)
    local keyRoot, valRoot = C.AddVariableRoot(keyName), C.AddVariableRoot(valueName)
    body = body(C) -- First pass 
    local objs = C.PopVariableRoots(2)
    return function() -- Second pass:
        loopable(C)
        local preI = C.allocator.I
        C.allocator.Increment() -- Bump indices to account for loopable
        keyRoot.AllocateIndex() ; valRoot.AllocateIndex()
        C.Compile123("BC_PUSH_NIL", 0) ; local nextIdx = C.CompilePlaceholder()
        local N = compileObjPushes(C, objs)
        body(C)
        C.Compile123("BC_POPN", N - 1) -- Pop context variables, and the newly pushed value
        C.Compile123("BC_JMP", nextIdx) 
        C.Recompile123("BC_NEXT", C.BytesSize(), nextIdx)
        C.allocator.Reset(preI)
    end
end

function ForPairs(keyName) return function(valueName) return function(loopable) return function (...) 
    return makeLabelNode("ForPairs", {keyName, valueName, goal.ExprParse(loopable), goal.CodeBlock(...)})
end end end end
table.merge(basic, SNodes) -- SNodes is a superset

-- Program AST basic expressions:
local exprs = {} ; goal.BasicENodes = exprs

function exprs.TypeCheck(C, typeExpr, objExpr)
    local type = goal.TypeInfo.NameToType[typeExpr("").label]
    objExpr = goal.ExprParse(objExpr)(C)
    return function() 
        C.CompileConstant(type)
        objExpr(C)
        C.Compile123("BC_BIN_OP", goal.BIN_OP_TYPECHECK) 
    end
end

function exprs.RepeatString(C, str, numExpr)
    numExpr = goal.ExprParse(numExpr)(C)
    return function() 
        C.CompileConstant(str)
        numExpr(C)
        C.Compile123("BC_BIN_OP", goal.BIN_OP_REPEAT) 
    end
end

function exprs.var(C, repr) return C.ResolveObjectRef(repr) end

function exprs.Constant(C, val) return function() C.CompileConstant(val) end end

local function unaryOp(op) return function(C, val)
    val = goal.ExprParse(val)(C) ; return function() val(C) ; C.Compile123("BC_UNARY_OP", op) end
end end

function exprs.NodeDepth(C)
    return function() C.Compile123("BC_PUSH_NODE_DEPTH", 0) end
end

function exprs.Parent(C, --[[Optional]] parentNum)
    parentNum = parentNum or 1
    return function() C.Compile123("BC_PUSH_PARENT", parentNum) end
end

local function binOp(op) return function(C, val1, val2)
    val1 = goal.ExprParse(val1)(C)
    val2 = goal.ExprParse(val2)(C)
    return function() 
        val1(C) ; val2(C) ; C.Compile123("BC_BIN_OP", op) 
    end
end end
for k,v in pairs { Not = goal.UNARY_OP_NOT, Len = goal.UNARY_OP_LEN } do exprs[k] = unaryOp(v) end
for k,v in pairs { And = goal.BIN_OP_AND, Or = goal.BIN_OP_OR, Xor = goal.BIN_OP_XOR, Index = goal.BIN_OP_INDEX, Concat = goal.BIN_OP_CONCAT, Equal = goal.BIN_OP_EQUAL } do exprs[k] = binOp(v) end
table.merge(exprs, ENodes) -- ENodes is a superset of exprs

-- Makes the AST nodes that form expressions look kind-of like lua refs:
local VarBuilder = class "VarBuilder"

function VarBuilder:init(repr) self.repr = repr end

function VarBuilder:__index(k) return VarBuilder(self.repr .. '.' .. k) end

function VarBuilder:__call(k)
    k = (type(k) == "string") and k or k.repr ; local repr = k .. "." .. self.repr
    local varNode = simpleNode("var", repr) ; varNode.repr = repr ; return varNode
end
for k,v in pairs(goal) do -- Find all 'special' member names
    if k:find("SMEMBER_") == 1 then k = k:sub(#"SMEMBER_" + 1) 
        goal.API(k, VarBuilder(k)) 
    end
end

-- Discover all child labels for all complex nodes:

local function makeNT(...)
    local nt = NodeTransformer(...) ; for label in nt.AllLabelValues() do
        goal.API(label, function(...) return simpleNode(label, ...) end) 
    end ; return nt
end

local function forward(...) local args = pack(...) ; assert(#args == 1) ; return args[1].values[1] end

local function unwrapped(f) return function (...) 
    local args = pack(...) ; assert(#args == 1) ; return f(unpack(args[1].values)) 
end end

local function resolveTableNode(t, C, ...) 
    local args,newArgs=pack(...),{} ; for v in values(args) do append(newArgs, t.values[v](C)) end ; return unpack(newArgs)
end
local resList = {} -- List of deferred functions, used for root-level call chains like Case

function goal.FlushDefers() local R = resList ; resList = {} ; for r in values(R) do r() end end 

function goal.Defer(v) goal.FlushDefers(); append(resList, v) end 

-- Discover all statement & expression label nodes:
for label,v in pairsAll(SNodes, ENodes) do
    goal.API(label, rawget(_G, label) or function(...) return simpleNode(label, ...) end) 
end
local eventChildren = {}
for k, v in pairs(goal.TypeInfo.NameToType) do eventChildren[k] = valueNode end 

-- Root level functions
for root in values {
    -- Define 'Analyze', a function which calls 'AnalyzeAll' on 
    -- the GlobalSymbolContext in Go
    makeNT("Analyze", { Files = listNode, Database = valueNode }, true, 
        function(t)
            goal.FlushDefers()
            ColorPrint("36;1", "-- ANALYZING:\n")
            local files = {} ; for v in values(t.values.Files) do 
                if type(v) == "table" then Map(Curry(append,files), v)
                else append(files,v) end
            end 
            goal.GlobalSymbolContext.AnalyzeAll(files)
            goal.Commit()
            ColorPrint("36;1", "-- FINISHED ANALYZING.\n")
        end),
    makeNT("Event", eventChildren, true,
        function(t)
            goal.FlushDefers()
            local event, varName = table.next(t.values) -- Find first
            return function(...) goal.PushEvent(event, goal.Compile(goal.CodeParse(...), varName)) end
        end)
} do 
    goal.API(root.label, root)
end

-- Data definition
function Key(str) return simpleNode("Key", str) end

function Data(name) return function(...)
    local fields,keys = {},{}
    for v in values(pack(...)) do
        if type(v) == "string" then append(fields, v) else append(fields, v.values[1]) ; append(keys, v.values[1]) end
    end
    goal.DefineData(name, fields, keys)
end end


-- Various constants

function Constant(val) return simpleNode("Constant", val) end

function FindFiles(dir, --[[Optional]] filter)
    local args = {}
    local files = goal.FindGoFiles(dir)
    for i=1,#files do if not filter or filter(files[i]) then append(args, files[i]) end end
    return args
end

function FindPackages(dir, --[[Optional]] filter)
    local args = {}
    local files = goal.FindSubdirectories(dir)
    for i=1,#files do if not filter or filter(files[i]) then append(args, files[i]) end end
    return args
end


function DataSet(dbKind, fileName, --[[Optional, default true]] removePrevious) 
    removePrevious = removePrevious or (removePrevious == nil)
    goal.OpenConnection(dbKind, fileName, removePrevious)
end

DataClose = goal.CloseConnection ; DataCommit = goal.Commit

function DataQuery(...)
    local ret = {} ; local columns,results = goal.Query(...)
    for i, result in ipairs(results) do
        ret[i] = {} ; for j, subresult in ipairs(result) do
            if type(subresult) == "userdata" then
                subresult = goal.BytesToString(subresult)
            end
            ret[i][columns[j]] = subresult 
        end
    end ; return ret
end

function DataExec(execStr, ...) 
	local db = gsym.DB
	local statement, err = db.Prepare(execStr)
	if err then error(err) end
	local tx, err = db.Begin()
	if err then error(err) end
	local res, err = tx.Stmt(statement).Exec(...)
	if err then error(err) end
	tx.Commit()
	return res
end

True, False = Constant(true), Constant(false)
Otherwise = True ; Always = True
 -- Expose all object members
for i=1,#goal.TypeInfo.TypeMembers do
    local k = goal.TypeInfo.TypeMembers[i]
     goal.API(k, rawget(_G, k) or VarBuilder(goal.TypeInfo.TypeMembers[i]))
end

local macros = {}

function macros.CaseType(value)
    -- See test 09 for a use example.
    -- Syntatic sugar backflips follow:
    local conditionWrap,statementWrap
    function conditionWrap(f) return function(type)
        return statementWrap(f(TypeCheck(type, value)))
    end end
    function statementWrap(f) return function(...)
        local R = f(...) ; return goal.CallableNode(R, conditionWrap(R))
    end end
    return conditionWrap(Case)
end

local function EventCaseWrap(casef) return function(ev, --[[Optional]] val)
    local innerCase = val and casef(val) or casef
    goal.Defer(
        function() Event(ev)(innerCase)
    end)
    local function chainCall(...) innerCase = innerCase(...) ; return chainCall end ; return chainCall
end end
macros.EventCase = EventCaseWrap(Case)

-- Right to the point if you want a type switch, usually 
macros.EventCaseType = EventCaseWrap(macros.CaseType)

function macros.ForAll(value) return ForPairs("")(value) end

-- Expose macros to API:
for k, v in pairs(macros) do 
    goal.API(k, v)
end

