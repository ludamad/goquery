package goquery

import (
	"database/sql"

	"go/ast"
	"go/token"
)

type astState struct {
	context      *SymbolContext
	db           *sql.DB
	conf         Configuration
	file         *ast.File
	tokenFile    *token.File
	currentScope map[*ast.Object]bool
}

type AstContext struct {
	*astState
	functionContext *ast.FuncDecl
}

type AstVisitor interface {
	// Return whether to navigate to the children nodes
	Visit(node ast.Node, ac AstContext) bool
}

// Bridge to go's AST traversal API:
type visitorImpl struct {
	ast     AstContext
	visitor AstVisitor
}

func (v visitorImpl) Visit(node ast.Node) ast.Visitor {
	funcNode, _ := node.(*ast.FuncDecl)
	// If we are in a function node, set the function context
	if funcNode != nil {
		v.ast.functionContext = funcNode
	}
	visitChildren := v.visitor.Visit(node, v.ast)
	if visitChildren {
		return v
	} else {
		return nil
	}
}
