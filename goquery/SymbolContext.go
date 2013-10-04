package goquery

import (
	"log"

	"../go-future/types"
	"go/ast"
	"go/parser"
	"go/token"

	"database/sql"
	_ "github.com/mattn/go-sqlite3"
)

// Public API
type SymbolContext struct {
	fileSet    *token.FileSet
	files      []*ast.File
	exprToType map[ast.Expr]types.Type
}

func NewContext() SymbolContext {
	return SymbolContext{token.NewFileSet(), []*ast.File{}, map[ast.Expr]types.Type{}}
}

func (context *SymbolContext) Parse(files []string) {
	for _, filename := range files {
		context.parseFile(filename)
	}
	context.resolveTypes()
}

func (context *SymbolContext) DatabaseInsert(db *sql.DB) {
	for _, file := range context.files {
		ast.Inspect(file, func(n ast.Node) bool {
			context.handleNode(db, file, n)
			return true
		})
	}
}

// Internal functions
func (context *SymbolContext) parseFile(filename string) {
	file, err := parser.ParseFile(context.fileSet, filename, nil, parser.DeclarationErrors|parser.AllErrors)
	if err != nil {
		panic(err)
	}
	context.files = append(context.files, file)
}

func (context *SymbolContext) resolveTypes() {
	ctxt := types.Default
	ctxt.Error = func(err error) { log.Fatal(err) }
	ctxt.Expr = func(x ast.Expr, typ types.Type, val interface{}) {
		context.exprToType[x] = typ
		//		ast.Fprint(os.Stdout, fset, x, nil)
		//		fmt.Println(x, TypeRepresentation(typ), val)
	}
	ctxt.Check(context.fileSet, context.files)
}

func (context *SymbolContext) handleNode(db *sql.DB, file *ast.File, n ast.Node) {
	switch n.(type) {
	case *ast.FuncDecl:
		f, _ := n.(*ast.FuncDecl)
		if f.Recv != nil {
			name := f.Name.Name
			recvType := f.Recv.List[0].Type
			signatureType := f.Type
			DBAddMethodDeclaration(db, MethodDeclaration{name, context.exprRepr(signatureType), context.exprRepr(recvType)})
		}
	case *ast.TypeSpec:
		t, _ := n.(*ast.TypeSpec)
		context.handleTypeSpecNode(db, file, t)
	}
}

func (context *SymbolContext) handleTypeSpecNode(db *sql.DB, file *ast.File, t *ast.TypeSpec) {
	name := file.Name.Name + "." + t.Name.Name // A beauty
	DBAddTypeDeclaration(db, TypeDeclaration{name, context.exprRepr(t.Type)})
	switch t.Type.(type) {
	case *ast.InterfaceType:
		requirements := []InterfaceRequirement{}
		iface, _ := t.Type.(*ast.InterfaceType)
		for _, method := range iface.Methods.List {
			requiredName := method.Names[0].Name
			req := InterfaceRequirement{requiredName, context.exprRepr(method.Type)}
			requirements = append(requirements, req)
		}
		DBAddInterfaceDeclaration(db, InterfaceDeclaration{name, requirements})
	}
}

func (context *SymbolContext) lookupType(expr ast.Expr) types.Type {
	return context.exprToType[expr]
}

func (context *SymbolContext) exprRepr(expr ast.Expr) string {
	return TypeRepresentation(context.lookupType(expr))
}
