package goquery

import (
	"../go-future/types"
	"go/ast"
	"go/token"
)

type SymbolContext struct {
	fileSet       *token.FileSet
	nameToAstFile map[string]*ast.File
	exprToType    map[ast.Expr]types.Type
}

func NewContext() SymbolContext {
	return SymbolContext{token.NewFileSet(), map[string]*ast.File{}, map[ast.Expr]types.Type{}}
}

func (context *SymbolContext) fileList() []*ast.File {
	list := []*ast.File{}
	for _, file := range context.nameToAstFile {
		list = append(list, file)
	}
	return list
}
