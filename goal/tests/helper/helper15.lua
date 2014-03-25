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

local function nodeData(name) return function(...)
    Data(name) (
        Key "tag:INTEGER", 
        Key "id:INTEGER", -- ID of codeblock object
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
        "block_tag:INTEGER" 
    )
end

function FuncDeclNode:emit_event(Tag)
    EventCase(FuncDecl "n") (receiver "n") (
    )(Otherwise) (
        Store "functions" (Tag, id "n", location "n", name "n", typeof "n", Body.id "n")
    )
end

-- BlockStmt
local BlockStmtNode = newtype()
function BlockStmtNode:init() end

function BlockStmtNode:create_table()
    nodeData "blocks" (
        Key "entry_num:INTEGER", 
        "entry_tag:INTEGER"
    )
end

function BlockStmtNode:emit_event(Tag)
    Event(BlockStmt "n") (
        ForPairs "k" "v" (List "n") (
            Store "blocks" (Tag, id "n", location "n", var "k", id "v")
        )
    )
end

-- Various expression nodes
local ExprNode = newtype()

function ExprNode:init(name, --[[Optional]] data, --[[Optional]] children, --[[Optional]] optional)
    data = data or {}
    children  = children or {}
    optional = optional or {}

    self.name = name
    self.data = data
    self.children = children
    self.optional = optional

    self.dbArgs = {}
    for i,v in ipairs(data) do append(self.dbArgs, v) end
    for i,v in ipairs(children) do append(self.dbArgs, v .. "_id:INTEGER NOT NULL") end
    for i,v in ipairs(optional) do append(self.dbArgs, v .. "_id:INTEGER") end
end

function ExprNode:create_table()
    -- Make an appropriate database table:
    nodeData(self.name) (unpack(self.dbArgs))
end

function ExprNode:emit_event(Tag)
    local data,children,optional=self.data,self.children,self.optional

    -- Define an event to dump into the created table:
    local tuple_elems = {}
    for i,v in ipairsAll(data) do
        append(tuple_elems, var("n."..v)) 
    end
    for i,v in ipairsAll(children, optional) do
        append(tuple_elems, var("n."..v..".id") )
    end
    local event = _G[self.name]
    Event(event "n") (
        Store(self.name)(Tag, id "n", location "n", -- Common component
            unpack(tuple_elems)
        )
    )
end

--------------------------------------------------------------------------------
-- Create & return node types
--------------------------------------------------------------------------------

local node_types = {
  FuncDeclNode.create(),
  BlockStmtNode.create()
}

for name, schema in pairs {
    FuncLit = {
        data = {"typeof"},
        children = {"Body"}
    },

    Ellipsis = {
        optional = {"Elt"}
    },

    CompositeLit = {
        data = {"typeof"}
--        walkExprList(Elts "n")
    },

    ParenExpr = {
        children = {"X"}
    },

    SelectorExpr = {
        children = {"X", "Sel"}
    },
    IndexExpr = {
        children = {"X", "Index"}
    },
    SliceExpr = {
        children = {"X"},
        optional = {"Low", "High", "Max"}
    },
    TypeAssertExpr = {
        data = {"typeof"},
        children = {"X"}
    },
    CallExpr = {
        children = {"Fun"}
--        walkExprList(Args "n")
    },
    StarExpr = {
        children = {"X"}

    },
    UnaryExpr = {
        children = {"X"}
    },
    BinaryExpr = {
        children = {"X", "Y"}
    },
    KeyValueExpr = {
        children = {"Key", "Value"}
    },
    -- Types
    ArrayType = {
        optional = {"Len"},
        children = {"Elt"}
    },
    StructType = {
        children = {"Fields"}
    },
    InterfaceType = {
        children = {"Methods"}
    },
    MapType = {
        children = {"Key", "Value"}
    },
    ChanType = {
        children = {"Value"}
    },
    DeclStmt = {
        children = {"Decl"}
    },
    LabeledStmt = {
        children = {"Label", "Stmt"}
    },
    ExprStmt = {
        children = {"X"}
    },
    SendStmt = {
        children = {"Chan", "Value"}
    },
    IncDecStmt = {
        children = {"X"}

    },
   -- AssignStmt = {
   --     walkExprList(Lhs "n")
   --     walkExprList(Rhs "n")
   -- },
    GoStmt = {
        children = {"Call"}
    },
    DeferStmt = {
        children = {"Call"}
    },
    ReturnStmt = {
    --    walkExprList(Results "n")
    --
      },
    BranchStmt = {
            optional = {"Label"}
    },
    BlockStmt = {
    --    walkStmtList(List "n")
    },
    IfStmt = {
        optional = {"Init", "Else"},
        children = {"Cond", "Body"}
    },
    CaseClause = {
--        walkExprList(List "n")
--        walkStmtList(Body "n")
    },
--
--    SwitchStmt = {
--            optional = {"Init"}
--            optional = {"Tag"}
--        children = {"Body"}
--    },
--    TypeSwitchStmt = {
--            optional = {"Init"}
--        Assign
--        Body
--
--    },
--    CommClause = {
--        if n.Comm != nil {
--            Comm
--        }
--        walkStmtList(Body "n")
--
--    },
--    SelectStmt = {
--        Body
--
--    },
--    ForStmt = {
--        if n.Init != nil {
--            Init
--        }
--        if n.Cond != nil {
--            Cond
--        }
--        if n.Post != nil {
--            Post
--        }
--        Body
--
--    },
--    RangeStmt = {
--        Key
--        if n.Value != nil {
--            Value
--        }
--        X
--        Body
--
--    },
--    ImportSpec = {
--        if n.Doc != nil {
--            Doc
--        }
--        if n.Name != nil {
--            Name
--        }
--        Path
--        if n.Comment != nil {
--            Comment
--        }
--
--    },
--    ValueSpec = {
--        if n.Doc != nil {
--            Doc
--        }
--        walkIdentList(Names "n")
--        if n.Type != nil {
--            Type
--        }
--        walkExprList(Values "n")
--        if n.Comment != nil {
--            Comment
--        }
--    },
    TypeSpec = {
        children = {"Type"} 
    }
} do
   local nt = ExprNode.create(name, schema.data, schema.children, schema.optional)
   append(node_types, nt)   
end

return node_types
