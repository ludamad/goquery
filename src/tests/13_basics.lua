--Getter "N.location" (
--    Pos "N"
--    pos := fileSym.TokenFile.Position(node.Pos())
--    return fmt.Sprintf("%s:%d:%d", pos.Filename, pos.Line, pos.Column)
--    
--) 
--
--Getter "N.location" (
--    Return(Sprintf("%s:%d:%d", Pos.Filename "N"))
--)

--
--
--    switch node := n.Value.(type) {
--    case *ast.FuncDecl:
--        if memberIdx == SMEMBER_type {
--            return makeStrRef(bc.ExprRepr(node.Type))
--        } else if memberIdx == SMEMBER_name {
--            return makeStrRef(node.Name.Name)
--        } else if memberIdx == SMEMBER_receiver {
--            if node.Recv == nil {
--                return goalRef{_TYPE_INFO.fieldTypeTable, nil}
--            }
--            return goalRef{_TYPE_INFO.fieldTypeTable, node.Recv.List[0]}
--        }
--    case *ast.Field:
--        if memberIdx == SMEMBER_type {
--            return makeStrRef(bc.ExprRepr(node.Type))
--        } else if memberIdx == SMEMBER_name {
--            return makeStrRef(node.Names[0].Name)
--        }
--    case *ast.TypeSpec:
--        if memberIdx == SMEMBER_type {
--            return makeStrRef(bc.ExprRepr(node.Type))
--        } else if memberIdx == SMEMBER_name {
--            return makeStrRef(bc.File.Name.Name + "." + node.Name.Name) // A beauty
--        }
--    }
--    if memberIdx == SMEMBER_location {
--        return makeStrRef(bc.PositionString(n.Value.(ast.Node)))
--    }
