package main

import (
	"bytes"
	"database/sql"
	"flag"
	_ "github.com/mattn/go-sqlite3"
//		"fmt"
	"./db"
	"go/ast"
	"go/parser"
	_ "go/printer"
	"go/token"
	"go/types"
	"log"
	"strconv"
)

var FOO = 1

func _VarListRepresentation(buffer *bytes.Buffer, vars []*types.Var, separator string) {
	for i, v := range vars {
		_TypeRepresentation(buffer, v.Type)
		if i < len(vars)-1 {
			buffer.WriteString(separator)
		}
	}
}

func _TypeRepresentation(buffer *bytes.Buffer, typ types.Type) {
	switch typ.(type) {
	case *types.Slice:
		p, _ := typ.(*types.Slice)
		buffer.WriteString("[]")
		_TypeRepresentation(buffer, p.Elt)
	case *types.Array:
		p, _ := typ.(*types.Array)
		buffer.WriteString("[" + strconv.Itoa(int(p.Len)) + "]")
		_TypeRepresentation(buffer, p.Elt)
	case *types.Map:
		p, _ := typ.(*types.Map)
		buffer.WriteString("map[")
		_TypeRepresentation(buffer, p.Key)
		buffer.WriteString("]")
		_TypeRepresentation(buffer, p.Elt)
	case *types.Pointer:
		p, _ := typ.(*types.Pointer)
		buffer.WriteString("*")
		_TypeRepresentation(buffer, p.Base)
	case *types.Signature:
		sig, _ := typ.(*types.Signature)
		buffer.WriteString("func(")
		_VarListRepresentation(buffer, sig.Params, ", ")
		buffer.WriteString(")")

	case *types.NamedType:
		namedType, _ := typ.(*types.NamedType)
		pkg := namedType.Obj.GetPkg()
		if pkg.Path != "" {
			buffer.WriteString(namedType.Obj.GetPkg().Path)
		} else {
			buffer.WriteString(pkg.Name)
		}
		buffer.WriteRune('.')
		buffer.WriteString(namedType.Obj.Name)
	default:
		buffer.WriteString(typ.String())
	}
}

type SymbolContext struct {
	fileSet    *token.FileSet
	files      []*ast.File
	exprToType map[ast.Expr]types.Type
	db *sql.DB
}

func NewContext() SymbolContext {
	db := db.DBInitialize()
	return SymbolContext{token.NewFileSet(), []*ast.File{}, map[ast.Expr]types.Type{}, db}
}

func (context *SymbolContext) parseFile(filename string) {
	file, err := parser.ParseFile(context.fileSet, filename, nil, parser.DeclarationErrors|parser.AllErrors)
	if err != nil {
		panic(err)
	}
	context.files = append(context.files, file)
}

func (context *SymbolContext) lookupType(expr ast.Expr) types.Type {
	return context.exprToType[expr]
}

func (context *SymbolContext) exprRepr(expr ast.Expr) string {
	return TypeRepresentation(context.lookupType(expr))
}

func (context *SymbolContext) checkTypes() {
	ctxt := types.Default
	ctxt.Error = func(err error) { log.Fatal(err) }
	ctxt.Expr = func(x ast.Expr, typ types.Type, val interface{}) {
		context.exprToType[x] = typ
		//		ast.Fprint(os.Stdout, fset, x, nil)
		//		fmt.Println(x, TypeRepresentation(typ), val)
	}
	ctxt.Check(context.fileSet, context.files)
}

func TypeRepresentation(typ types.Type) string {
	var buffer bytes.Buffer
	_TypeRepresentation(&buffer, typ)
	return buffer.String()
}

func HandleTypeSpecNode(context *SymbolContext, file *ast.File, t *ast.TypeSpec) {
	name := file.Name.Name  + "." + t.Name.Name // A beauty
	db.DBAddTypeDeclaration(context.db, db.TypeDeclaration{name,  context.exprRepr(t.Type)})
	switch t.Type.(type) {
		case *ast.InterfaceType:
			requirements := []db.InterfaceRequirement{}
			iface, _ := t.Type.(*ast.InterfaceType)
			for _,method := range iface.Methods.List {
				requiredName := method.Names[0].Name
				req := db.InterfaceRequirement{requiredName, context.exprRepr(method.Type)}
				requirements = append(requirements, req)
			}
			db.DBAddInterfaceDeclaration(context.db, db.InterfaceDeclaration{name, requirements})
	}
}

func HandleNode(context *SymbolContext, file *ast.File, n ast.Node) {
	switch n.(type) {
	case *ast.FuncDecl:
		f, _ := n.(*ast.FuncDecl)
		if f.Recv != nil {
			name := f.Name.Name
			recvType := f.Recv.List[0].Type
			signatureType := f.Type
			db.DBAddMethodDeclaration(context.db, db.MethodDeclaration{name, context.exprRepr(signatureType), context.exprRepr(recvType)})
		}
	case *ast.TypeSpec:
		t, _ := n.(*ast.TypeSpec)
		HandleTypeSpecNode(context, file, t)
	}
}

func main() {
	flag.Parse()

	context := NewContext()
	for _, filename := range flag.Args() {
		context.parseFile(filename)
	}
	context.checkTypes()

	for _, file := range context.files {
		ast.Inspect(file, func(n ast.Node) bool {
			HandleNode(&context, file, n)
			return true
		})
	}
}
