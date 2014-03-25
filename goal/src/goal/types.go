package goal

import (
	"bytes"
	"strconv"
	//"strings"

	"fmt"
	"go/ast"
	"os"

	_ "code.google.com/p/go.tools/go/gcimporter"
	"code.google.com/p/go.tools/go/types"
)

// Public API
func TypeRepresentation(typ types.Type) string {
	var buffer bytes.Buffer
	typeRepresentation(&buffer, typ)
	return buffer.String()
}

// Internal functions
func varListRepresentation(buffer *bytes.Buffer, tuple *types.Tuple, separator string) {
	for i := 0; i < tuple.Len(); i++ {
		typeRepresentation(buffer, tuple.At(i).Type())
		if i < tuple.Len()-1 {
			buffer.WriteString(separator)
		}
	}
}

func typeRepresentation(buffer *bytes.Buffer, typ types.Type) {
	switch typ.(type) {
	case *types.Slice:
		p, _ := typ.(*types.Slice)
		buffer.WriteString("[]")
		typeRepresentation(buffer, p.Elem())
	case *types.Array:
		p, _ := typ.(*types.Array)
		buffer.WriteString("[" + strconv.Itoa(int(p.Len())) + "]")
		typeRepresentation(buffer, p.Elem())
	case *types.Map:
		p, _ := typ.(*types.Map)
		buffer.WriteString("map[")
		typeRepresentation(buffer, p.Key())
		buffer.WriteString("]")
		typeRepresentation(buffer, p.Elem())
	case *types.Pointer:
		p, _ := typ.(*types.Pointer)
		buffer.WriteString("*")
		typeRepresentation(buffer, p.Elem())
	case *types.Signature:
		sig, _ := typ.(*types.Signature)
		buffer.WriteString("func(")
		varListRepresentation(buffer, sig.Params(), ", ")
		buffer.WriteString(")")

	case *types.Named:
		namedType, _ := typ.(*types.Named)
		pkg := namedType.Obj().Pkg()
		if pkg != nil && pkg.Path() != "" {
			buffer.WriteString(pkg.Path())
		} else if pkg != nil {
			buffer.WriteString(pkg.Name())
		}
		buffer.WriteRune('.')
		buffer.WriteString(namedType.Obj().Name())
	default:
		buffer.WriteString(typ.String())
	}
}

func (context *GlobalSymbolContext) inferTypes(base string, name string, files []*ast.File) {
	var ctxt types.Config

	ctxt.FakeImportC = true

	var cachedErr error
	ctxt.Error = func(err error) {
		cachedErr = err
		//if strings.Contains(err.Error(), "import") {
		fmt.Println("A problem occurred in inferTypes:\n", err)
		//}
	}
	ctxt.IgnoreFuncBodies = false
	prevWd := getWD()
	setWD(base)
	ctxt.Check(name, context.FileSet, files, context.Info)
	setWD(prevWd)
	//mt.Println(err)
}

func getWD() string {
	prevWd, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	return prevWd
}

func setWD(wd string) {
	err := os.Chdir(wd)
	if err != nil {
		panic(err)
	}
}

func (context *GlobalSymbolContext) LookupType(expr ast.Expr) types.Type {
	obj := context.Info.Types[expr]
	typ := obj.Type
	if typ == nil {
		//fmt.Println("GOTOTOT")
		//for k, v := range context.Info.Types {
		//	fmt.Printf("RECORDED x=%#v, typ=%#v\n", k, v)

		//}
		//panic("TEST")
		//p, _ := expr.(*ast.FuncType)
		//fmt.Printf("Types: %v\n: ", context.Info.Types)
		//fmt.Printf("Implicits: %v\n: ", context.Info.Implicits)
		//fmt.Printf("Objects: %v\n: ", context.Info.Objects)
		//fmt.Printf("Scopes: %v\n: ", context.Info.Scopes)
		//fmt.Printf("Selections: %v\n: ", context.Info.Selections)
	}
	return typ
}

func (context *GlobalSymbolContext) ellipseRepr(expr ast.Expr) string {
	ellips, ok := expr.(*ast.Ellipsis)
	if ok { // Special case, ellipsis type
		typ := context.LookupType(ellips.Elt)
		return "..." + TypeRepresentation(typ)
	}
	return ""
}

func (context *GlobalSymbolContext) ExprRepr(expr ast.Expr) string {
	ellips := context.ellipseRepr(expr)
	if ellips != "" {
		return ellips
	}
	//fmt.Printf("\n>>.ExprRepr x=%#v, typ=%#v\n\n", expr, context.LookupType(expr))
	return TypeRepresentation(context.LookupType(expr))
}

func (context *GlobalSymbolContext) exprReprRef(expr ast.Expr) goalRef {
	ellips := context.ellipseRepr(expr)
	if ellips != "" {
		return makeStrRef(ellips)
	}
	//fmt.Printf("** Lookup: %+v \n", expr)
	typ := context.LookupType(expr)
	if typ == nil {
		//fmt.Printf("NO GET x=%#v, typ=%#v\n", expr, typ)
		return makeStrRef(nil)
	}
	//fmt.Printf("!**GET x=%#v, typ=%#v\n", expr, typ)
	return makeStrRef(TypeRepresentation(typ))
}
