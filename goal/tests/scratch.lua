--    Event (Field "n") (
--     `   if n.Doc != nil {
--            Walk(Doc "n")
--        }
--        walkIdentList(Names "n")
--        Walk(Type "n")
--        if n.Tag != nil {
--            Walk(Tag "n")
--        }
--        if n.Comment != nil {
--            Walk(Comment "n")
--        }
--    )

    Event (FieldList "n") (
        for _, f  "n") (
            Walk(v, f)
        }
    )

local eventData = {
    FuncLit = {
        data = {"type"},
        children = {"type"}
        optional = {"type"}
    },
    FuncLit = {
        data = {"type"},
        children = {"type"}
        optional = {"type"}
    }
}


    Event (Ellipsis "n") (
        if n.Elt != nil {
            Walk(Elt "n")
        }

    Event (FuncLit "n") (
        Walk(Type "n")
        Walk(Body "n")
    )

    Event (CompositeLit "n") (
        if n.Type != nil {
            Walk(Type "n")
        }
        walkExprList(Elts "n")

    Event (ParenExpr "n") (
        Walk(X "n")

    Event (SelectorExpr "n") (
        Walk(X "n")
        Walk(Sel "n")

    Event (IndexExpr "n") (
        Walk(X "n")
        Walk(Index "n")

    Event (SliceExpr "n") (
        Walk(X "n")
        if n.Low != nil {
            Walk(Low "n")
        }
        if n.High != nil {
            Walk(High "n")
        }
        if n.Max != nil {
            Walk(Max "n")
        }

    Event (TypeAssertExpr "n") (
        Walk(X "n")
        if n.Type != nil {
            Walk(Type "n")
        }

    Event (CallExpr "n") (
        Walk(Fun "n")
        walkExprList(Args "n")

    Event (StarExpr "n") (
        Walk(X "n")

    Event (UnaryExpr "n") (
        Walk(X "n")

    Event (BinaryExpr "n") (
        Walk(X "n")
        Walk(Y "n")

    Event (KeyValueExpr "n") (
        Walk(Key "n")
        Walk(Value "n")

    // Types
    Event (ArrayType "n") (
        if n.Len != nil {
            Walk(Len "n")
        }
        Walk(Elt "n")

    Event (StructType "n") (
        Walk(Fields "n")

    Event (FuncType "n") (
        if n.Params != nil {
            Walk(Params "n")
        }
        if n.Results != nil {
            Walk(Results "n")
        }

    Event (InterfaceType "n") (
        Walk(Methods "n")

    Event (MapType "n") (
        Walk(Key "n")
        Walk(Value "n")

    Event (ChanType "n") (
        Walk(Value "n")

    Event (DeclStmt "n") (
        Walk(Decl "n")

    Event (EmptyStmt "n") (
        // nothing to do

    Event (LabeledStmt "n") (
        Walk(Label "n")
        Walk(Stmt "n")

    Event (ExprStmt "n") (
        Walk(X "n")

    Event (SendStmt "n") (
        Walk(Chan "n")
        Walk(Value "n")

    Event (IncDecStmt "n") (
        Walk(X "n")

    Event (AssignStmt "n") (
        walkExprList(Lhs "n")
        walkExprList(Rhs "n")

    Event (GoStmt "n") (
        Walk(Call "n")

    Event (DeferStmt "n") (
        Walk(Call "n")

    Event (ReturnStmt "n") (
        walkExprList(Results "n")

    Event (BranchStmt "n") (
        if n.Label != nil {
            Walk(Label "n")
        }

    Event (BlockStmt "n") (
        walkStmtList(List "n")

    Event (IfStmt "n") (
        if n.Init != nil {
            Walk(Init "n")
        }
        Walk(Cond "n")
        Walk(Body "n")
        if n.Else != nil {
            Walk(Else "n")
        }

    Event (CaseClause "n") (
        walkExprList(List "n")
        walkStmtList(Body "n")

    Event (SwitchStmt "n") (
        if n.Init != nil {
            Walk(Init "n")
        }
        if n.Tag != nil {
            Walk(Tag "n")
        }
        Walk(Body "n")

    Event (TypeSwitchStmt "n") (
        if n.Init != nil {
            Walk(Init "n")
        }
        Walk(Assign "n")
        Walk(Body "n")

    Event (CommClause "n") (
        if n.Comm != nil {
            Walk(Comm "n")
        }
        walkStmtList(Body "n")

    Event (SelectStmt "n") (
        Walk(Body "n")

    Event (ForStmt "n") (
        if n.Init != nil {
            Walk(Init "n")
        }
        if n.Cond != nil {
            Walk(Cond "n")
        }
        if n.Post != nil {
            Walk(Post "n")
        }
        Walk(Body "n")

    Event (RangeStmt "n") (
        Walk(Key "n")
        if n.Value != nil {
            Walk(Value "n")
        }
        Walk(X "n")
        Walk(Body "n")

    // Declarations
    Event (ImportSpec "n") (
        if n.Doc != nil {
            Walk(Doc "n")
        }
        if n.Name != nil {
            Walk(Name "n")
        }
        Walk(Path "n")
        if n.Comment != nil {
            Walk(Comment "n")
        }

    Event (ValueSpec "n") (
        if n.Doc != nil {
            Walk(Doc "n")
        }
        walkIdentList(Names "n")
        if n.Type != nil {
            Walk(Type "n")
        }
        walkExprList(Values "n")
        if n.Comment != nil {
            Walk(Comment "n")
        }

    Event (TypeSpec "n") (
        if n.Doc != nil {
            Walk(Doc "n")
        }
        Walk(Name "n")
        Walk(Type "n")
        if n.Comment != nil {
            Walk(Comment "n")
        }

    Event (BadDecl "n") (
        // nothing to do

    Event (GenDecl "n") (
        if n.Doc != nil {
            Walk(Doc "n")
        }
        for _, s  "n") (
            Walk(v, s)
        }

    Event (FuncDecl "n") (
        if n.Doc != nil {
            Walk(Doc "n")
        }
        if n.Recv != nil {
            Walk(Recv "n")
        }
        Walk(Name "n")
        Walk(Type "n")
        if n.Body != nil {
            Walk(Body "n")
        }

--    // Files and packages
--    Event (File "n") (
--        if n.Doc != nil {
--            Walk(Doc "n")
--        }
--        Walk(Name "n")
--        walkDeclList(Decls "n")
--        // don't walk n.Comments - they have been
--        // visited already through the individual
--        // nodes
--
--    Event (Package "n") (
--        for _, f  "n") (
--            Walk(v, f)
--        }
