local M = {}

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local config = {
    store_comments = true,
    store_location = true
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function create_common_tables()
    Data "node_data" (
        Key "tag:INTEGER", 
        Key "id:INTEGER", -- ID of object
        "kind", 
        "data", 
        "location",
        "type"
    )
    Data "node_links" (
        Key "tag:INTEGER", 
        Key "id:INTEGER", -- ID of object
        Key "label", 
        Key "link_number:INTEGER", 
        "link_id:INTEGER"
    )
end

local function nodeData(name) return function(...)
    Data(name) (
        Key "tag:INTEGER", 
        Key "id:INTEGER", -- ID of object
        "location",
        ...
    )
end end

--------------------------------------------------------------------------------
-- Node handler classes
--------------------------------------------------------------------------------

-- FuncDecl
local FuncDeclNode = newtype()
function FuncDeclNode:init() end

function FuncDeclNode:create_table()
    nodeData "functions" (
        "name", 
        "type",
        "block_id:INTEGER" 
    )
end

function FuncDeclNode:emit_event(Tag)
    EventCase(FuncDecl "n") (receiver "n") (
    )(Otherwise) (
        Store "functions" (Tag, id "n", location "n", name "n", type "n", Body.id "n")
    )
end

local NodeDumper = newtype()

function NodeDumper:init(name, --[[Optional]] data, --[[Optional]] children, --[[Optional]] lists)
    if data then
        data = var("n."..data)
    else
        data = Nil()
    end
    children  = children or {}
    lists = lists or {}

    self.data = data
    self.name = name
    self.children = children
    self.lists = lists

    self.dbArgs = {}
end

function NodeDumper:create_table() end

function NodeDumper:_handle_data(Tag)
    return Store "node_data" (Tag, id "n", 
            Constant(self.name), self.data,
            location "n", type "n"
    )
end
function NodeDumper:_handle_links(Tag)
    local links = {} 
    for i,child in ipairs(self.children) do
        append(links,
            Store "node_links" (Tag, id "n", Constant(child), Nil(), var("n.".. child .. ".id"))
        )
    end 
    for list in values(self.lists) do
        append(links, ForPairs "k" "v" (var("n."..list)) (
            Store "node_links" (Tag, id "n", Constant(list), var "k", id "v")
        ))
    end
    return links
end

function NodeDumper:emit_event(Tag)
    local event = _G[self.name]

    Event(event "n") (
        self:_handle_data(Tag), unpack(self:_handle_links(Tag))
    )
end

--------------------------------------------------------------------------------
-- Create & return node types
--------------------------------------------------------------------------------

local node_types = {
  FuncDeclNode.create()
}

local schemas = {}
local function Link(name) return function(...)
    schemas[name] = schemas[name] or {}
    schemas[name].children = {...}
end end

local function DataDef(name) return function(def)
    schemas[name] = schemas[name] or {}
    schemas[name].data = def
end end

local function ListLink(name) return function(...)
    schemas[name] = schemas[name] or {}
    schemas[name].lists = {...}
end end

-- Terminal nodes
DataDef "BasicLit" ("Value")
DataDef "Ident" ("Name")

-- Complex nodes
ListLink "CompositeLit" ("Elts")

Link     "CallExpr" ("Fun")
ListLink "CallExpr" ("Args")

ListLink "ReturnStmt" ("Results")
ListLink "AssignStmt" ("Lhs", "Rhs")
ListLink "BlockStmt" ("List")
ListLink "CaseClause" ("List", "Body")

Link     "CommClause" ("Comm")
ListLink "CommClause" ("Body")

-- Simple nodes

Link "FuncLit" ("Body")
Link "Ellipsis" ("Elt")
Link "ParenExpr" ("X")
Link "SelectorExpr" ("X", "Sel")
Link "IndexExpr" ("X", "Index")
Link "SliceExpr" ("X", "Low", "High", "Max")
Link "TypeAssertExpr" ("X")
Link "StarExpr" ("X")
Link "UnaryExpr" ("X")
Link "BinaryExpr" ("X", "Y")
Link "KeyValueExpr" ("Key", "Value")
Link "RangeStmt" ("Key", "Value", "X", "Body")

Link "ArrayType" ("Len", "Elt")
Link "FuncType" ("Params", "Results")
Link "StructType" ("Fields")
Link "InterfaceType" ("Methods")
Link "MapType" ("Key", "Value")
Link "ChanType" ("Value")
Link "DeclStmt" ("Decl")
Link "LabeledStmt" ("Label", "Stmt")
Link "ExprStmt" ("X")
Link "SendStmt" ("Chan", "Value")
Link "IncDecStmt" ("X")

-- Statements
Link "GoStmt" ("Call")
Link "DeferStmt" ("Call")
Link "BranchStmt" ("Label")
Link "IfStmt" ("Init", "Else", "Cond", "Body")
Link "SwitchStmt" ("Init", "Tag", "Body")
Link "TypeSwitchStmt" ("Init", "Assign", "Body")
Link "SelectStmt" ("Body")
Link "ForStmt" ("Init", "Cond", "Post", "Body")

-- Specifications
Link "TypeSpec" ("Type")
Link "ImportSpec" ("Doc", "Name", "Path", "Comment")

ListLink "ValueSpec" ("Names", "Values")
Link "ValueSpec" ("Doc", "Type", "Comment")

for name, schema in pairs(schemas) do
   local nt = NodeDumper.create(name, schema.data, schema.children, schema.lists)
   append(node_types, nt)   
end

--------------------------------------------------------------------------------
-- Initialization routines
--------------------------------------------------------------------------------

function M.init_database()
    create_common_tables()

    for nt in values(node_types) do
        nt:create_table()
    end
end

function M.emit_events(Tag)
    for nt in values(node_types) do
        nt:emit_event(Tag)
    end
end

return M
