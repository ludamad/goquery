package goal

import (
	"go/ast"
	"reflect"
	"strconv"
)

type FieldListLoop struct {
	fields []*ast.Field
	index  int
}

func (f *FieldListLoop) Enter(bc *BytecodeContext) bool {
	if f.index >= len(f.fields) {
		return false
	}
	bc.pushObject(f.fields[f.index])
	f.index++
	return true
}

func (f *FieldListLoop) Exit(bc *BytecodeContext) {
	bc.popObjects(1)
}

func (bc *BytecodeExecContext) resolveStringMember(objIdx int, memberIdx int) string {
	n := bc.ObjectStack[objIdx]

	switch node := n.(type) {
	case []string:
		return node[memberIdx]
	case *ast.FuncDecl:
		if memberIdx == SMEMBER_type {
			return bc.ExprRepr(node.Type)
		} else if memberIdx == SMEMBER_name {
			return node.Name.Name
		}
	case *ast.Field:
		if memberIdx == SMEMBER_type {
			return bc.ExprRepr(node.Type)
		} else if memberIdx == SMEMBER_name {
			return node.Names[0].Name
		}
	case *ast.TypeSpec:
		if memberIdx == SMEMBER_type {
			return bc.ExprRepr(node.Type)
		} else if memberIdx == SMEMBER_name {
			return node.Name.Name
		}
	}
	if memberIdx == SMEMBER_location {
		return bc.PositionString(n.(ast.Node))
	}
	panic("resolveObjectMember received unknown memberIdx " + strconv.Itoa(memberIdx) + " for " + reflect.TypeOf(n).String())
}

func (bc *BytecodeExecContext) resolveObjectMember(objIdx int, memberIdx int) interface{} {
	n := bc.ObjectStack[objIdx]
	switch memberIdx {
	case OMEMBER_Signature:
		node, ok := n.(*ast.FuncDecl)
		if !ok {
			panic("Could not convert to FuncDecl\n")
		}
		return node.Type
	case OMEMBER_Receiver:
		node, ok := n.(*ast.FuncDecl)
		if !ok {
			panic("Could not convert to FuncDecl\n")
		}
		if node.Recv == nil {
			return nil
		}
		return node.Recv.List[0]
	default:
		panic("resolveObjectMember received unknown memberIdx " + strconv.Itoa(memberIdx) + " for " + reflect.TypeOf(n).String())
	}
	return nil
}

func (bc *BytecodeContext) resolveLoop(objIdx int, loopKind int) LoopContext {
	n := bc.ObjectStack[objIdx]
	switch loopKind {
	case LMEMBER_Methods:
		iface := n.(*ast.InterfaceType)
		loop := &FieldListLoop{iface.Methods.List, 0}
		return LoopContext{loop, bc.Index + 1}
	}
	panic("resolveLoop received unknown loopKind " + strconv.Itoa(loopKind) + " for " + reflect.TypeOf(n).String())
}
