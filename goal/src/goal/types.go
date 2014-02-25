package goal

import (
	"bytes"
	"strconv"

	"fmt"
	"go/token"
	"go/ast"
	"reflect"

	"code.google.com/p/go.tools/go/types"
	 _ "code.google.com/p/go.tools/go/gcimporter"
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

func (context *GlobalSymbolContext) inferTypes(name string, fileSet *token.FileSet, file *ast.File) {
	var ctxt types.Config
	ctxt.Error = func(err error) {
		fmt.Println("A problem occurred in inferTypes:\n", err)
	}
	ctxt.Check(name, fileSet, []*ast.File{file}, context.Info)
}

func (context *GlobalSymbolContext) LookupType(expr ast.Expr) types.Type {
	obj := context.Info.Types[expr]
	typ := obj.Type
	if typ == nil {
		typ = obj.
	}
	return typ
}

func (context *GlobalSymbolContext) ExprRepr(expr ast.Expr) string {
	fmt.Printf("%v\n: ", reflect.TypeOf(expr))
	return TypeRepresentation(context.LookupType(expr))
}
