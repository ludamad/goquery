package goal

import (
	"bytes"
	"strconv"

	"fmt"
	"go/ast"
	"log"

	"go-future/types"
)

// Public API
func TypeRepresentation(typ types.Type) string {
	var buffer bytes.Buffer
	typeRepresentation(&buffer, typ)
	return buffer.String()
}

// Internal functions
func varListRepresentation(buffer *bytes.Buffer, vars []*types.Var, separator string) {
	for i, v := range vars {
		typeRepresentation(buffer, v.Type)
		if i < len(vars)-1 {
			buffer.WriteString(separator)
		}
	}
}

func typeRepresentation(buffer *bytes.Buffer, typ types.Type) {
	switch typ.(type) {
	case *types.Slice:
		p, _ := typ.(*types.Slice)
		buffer.WriteString("[]")
		typeRepresentation(buffer, p.Elt)
	case *types.Array:
		p, _ := typ.(*types.Array)
		buffer.WriteString("[" + strconv.Itoa(int(p.Len)) + "]")
		typeRepresentation(buffer, p.Elt)
	case *types.Map:
		p, _ := typ.(*types.Map)
		buffer.WriteString("map[")
		typeRepresentation(buffer, p.Key)
		buffer.WriteString("]")
		typeRepresentation(buffer, p.Elt)
	case *types.Pointer:
		p, _ := typ.(*types.Pointer)
		buffer.WriteString("*")
		typeRepresentation(buffer, p.Base)
	case *types.Signature:
		sig, _ := typ.(*types.Signature)
		buffer.WriteString("func(")
		varListRepresentation(buffer, sig.Params, ", ")
		buffer.WriteString(")")

	case *types.NamedType:
		namedType, _ := typ.(*types.NamedType)
		pkg := namedType.Obj.GetPkg()
		if pkg != nil && pkg.Path != "" {
			buffer.WriteString(namedType.Obj.GetPkg().Path)
		} else if pkg != nil {
			buffer.WriteString(pkg.Name)
		}
		buffer.WriteRune('.')
		buffer.WriteString(namedType.Obj.Name)
	default:
		buffer.WriteString(typ.String())
	}
}

func (context *GlobalSymbolContext) InferTypes() {
	ctxt := types.Default
	ctxt.Error = func(err error) {
		fmt.Println("A problem occurred in InferTypes:")
		log.Fatal(err)
	}
	ctxt.Expr = func(x ast.Expr, typ types.Type, val interface{}) {
		context.ExprToType[x] = typ
	}
	ctxt.Check(context.FileSet, context.FileList())
}

func (context *GlobalSymbolContext) LookupType(expr ast.Expr) types.Type {
	return context.ExprToType[expr]
}

func (context *GlobalSymbolContext) ExprRepr(expr ast.Expr) string {
	return TypeRepresentation(context.LookupType(expr))
}
