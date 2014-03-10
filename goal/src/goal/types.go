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

	//var scope *types.Scope
	//scope = pkg.Scope()
	//// IMPORTANT
	//// Fill in whatever type annotations may be missing:
	//for _, file := range files {
	//	ast.Inspect(file, func(node ast.Node) bool {
	//		expr, ok := node.(ast.Expr)
	//		//currentScope := context.Info.Scopes[node]
	//		//if currentScope != nil {
	//		//	currentScope =
	//		//}
	//		if ok {
	//			prev := context.Info.Types[expr]
	//			if prev.Type == nil {
	//				scope = context.Info.Scopes[node]
	//				if scope == nil {
	//					return true
	//				}
	//				fmt.Println("Scope defined for ", node)
	//				typ, _, err := types.EvalNode(context.FileSet, expr, pkg, scope)

	//				if err != nil {
	//					panic(err)
	//				}
	//				prev.Type = typ
	//				context.Info.Types[expr] = prev
	//			}
	//		}
	//		return true
	//	})
	//}

	//	//for k, vars := range context.Info.InitOrder {
	//	//	fmt.Printf("INITIALIZERS: %v %v\n", k, vars)
	//	//	for _, v := range vars.Lhs {
	//	//		context.Info.Types[vars.Rhs] = types.TypeAndValue{v.Type(), nil}
	//	//	}
	//	//}

	//	//for k, v := range context.Info.Types {
	//	//	fmt.Printf("Got from Info.Types: KEY(%s, %v), VAL(%s, %v)\n", reflect.TypeOf(k), k, reflect.TypeOf(v.Type), v)
	//	//}

	//	//for k, v := range context.Info.Implicits {
	//	//	fmt.Printf("Got from Info.Implicits: KEY(%s, %v), VAL(%s, %v)\n", reflect.TypeOf(k), k, reflect.TypeOf(v.Type), v)
	//	//}

	//	//for _, v := range context.Info.Objects {
	//	//	f, _ := v.(*types.Func)
	//	//	if f != nil {
	//	//		fmt.Printf("Got from Info.Objects: VAL(FUNC, %v, %v)\n", reflect.TypeOf(f.Type()), f.Type())
	//	//	}
	//	//}
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
		fmt.Printf("NO GET x=%#v, typ=%#v\n", expr, typ)
		return makeStrRef(nil)
	}
	fmt.Printf("!**GET x=%#v, typ=%#v\n", expr, typ)
	return makeStrRef(TypeRepresentation(typ))
}
