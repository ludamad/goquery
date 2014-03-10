package goal

import (
	"bytes"
	"strconv"

	"fmt"
	"go/ast"

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

func (context *GlobalSymbolContext) inferTypes(name string, files []*ast.File) {
	var ctxt types.Config

	ctxt.Error = func(err error) {
		fmt.Println("A problem occurred in inferTypes:\n", err)
	}
	ctxt.IgnoreFuncBodies = false
	_, err := ctxt.Check(name, context.FileSet, files, context.Info)

	if err != nil {
		fmt.Println(err)
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

func (context *GlobalSymbolContext) ExprRepr(expr ast.Expr) string {
	return TypeRepresentation(context.LookupType(expr))
}

func (context *GlobalSymbolContext) exprReprRef(expr ast.Expr) goalRef {
	typ := context.LookupType(expr)
	if typ == nil {
		//fmt.Printf("NO GET x=%#v, typ=%#v\n", expr, typ)
		return makeStrRef(nil)
	}
	//fmt.Printf("!**GET x=%#v, typ=%#v\n", expr, typ)
	return makeStrRef(TypeRepresentation(typ))
}
