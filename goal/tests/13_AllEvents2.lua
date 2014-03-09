require "goal"

local function installEvent(evStr)
    local eventType = _G[evStr]
    Event(eventType "n") (
        Printf("%s %s: "..evStr.." child\n", RepeatString("  ", NodeDepth()), location "n")

    )
end

for ev in values {
    "ArrayType",
    "AssignStmt",
    "BadDecl",
    "BadExpr",
    "BadStmt",
    "BasicLit",
    "BinaryExpr",
    "BlockStmt",
    "BranchStmt",
    "CallExpr",
    "CaseClause",
    "ChanDir",
    "ChanType",
    "CommClause",
    "Comment",
    "CommentGroup",
    "CommentMap",
    "CompositeLit",
    "Decl",
    "DeclStmt",
    "DeferStmt",
    "Ellipsis",
    "EmptyStmt",
    "ExprStmt",
    "Field",
    "FieldFilter",
    "FieldList",
    "File",
    "Filter",
    "ForStmt",
    "FuncDecl",
    "FuncLit",
    "FuncType",
    "GenDecl",
    "GoStmt",
    "Ident",
    "IfStmt",
    "ImportSpec",
    "Importer",
    "IncDecStmt",
    "IndexExpr",
    "InterfaceType",
    "KeyValueExpr",
    "LabeledStmt",
    "MapType",
    "MergeMode",
    "ObjKind",
    "Object",
    "Package",
    "ParenExpr",
    "RangeStmt",
    "ReturnStmt",
    "Scope",
    "SelectStmt",
    "SelectorExpr",
    "SendStmt",
    "SliceExpr",
    "StarExpr",
    "StructType",
    "SwitchStmt",
    "TypeAssertExpr",
    "TypeSpec",
    "TypeSwitchStmt",
    "UnaryExpr",
    "ValueSpec"
} do
    installEvent(ev)
end

Analyze (
    Files(FindPackages("src"))
)
