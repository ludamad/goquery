package goal

import (
	"go/ast"
	"reflect"
	"strconv"
)

type typeTable struct {
	memberTypes   []*typeTable
	memberIndices [][]int
}

type goalRef struct {
	*typeTable
	value interface{}
}

func fillMemberNames(typ reflect.Type, members map[string]bool) {
	if typ.Kind() == reflect.Struct {
		for i := 0; i < typ.NumField(); i++ {
			members[typ.Field(i).Name] = true
		}
	}
}
func makeTypeTable(tInfo *typeInfo, typ reflect.Type) {
	table := tInfo.typeTables[typ]
	if typ.Kind() == reflect.Struct {
		for i := 0; i < len(tInfo.TypeMembers); i++ {
			f, ok := typ.FieldByName(tInfo.TypeMembers[i])
			if !ok {
				table.memberIndices = append(table.memberIndices, nil)
				table.memberTypes = append(table.memberTypes, nil)
			} else {
				table.memberIndices = append(table.memberIndices, f.Index)
				table.memberTypes = append(table.memberTypes, tInfo.typeTables[f.Type])
			}
		}
	}
}

type typeInfo struct {
	typeTables       map[reflect.Type]*typeTable
	stringTypeTable *typeTable
	fieldTypeTable *typeTable
	TypeMembers      []string
	stringToMemberId map[string]int
}

func makeTypeInfo() typeInfo {
	types := []reflect.Type{
		reflect.TypeOf(""),
		reflect.TypeOf((*ast.FuncDecl)(nil)).Elem(),
		reflect.TypeOf((*ast.Field)(nil)).Elem(),
		reflect.TypeOf((*ast.TypeSpec)(nil)).Elem(),
		reflect.TypeOf((*ast.InterfaceType)(nil)).Elem(),
		reflect.TypeOf((*ast.Ident)(nil)).Elem(),
		reflect.TypeOf((*ast.BadExpr)(nil)).Elem(),
	}

	members := map[string]bool{}
	for _, typ := range types {
		fillMemberNames(typ, members)
	}
	tables := map[reflect.Type]*typeTable{}
	tInfo := typeInfo{tables, nil, nil, []string{}, map[string]int{}}
	for member, _ := range members {
		tInfo.stringToMemberId[member] = len(tInfo.TypeMembers)
		tInfo.TypeMembers = append(tInfo.TypeMembers, member)
	}
	for _, typ := range types {
		tables[typ] = &typeTable{[]*typeTable{}, [][]int{}}
	}
	for _, typ := range types {
		makeTypeTable(&tInfo, typ)
	}
	tInfo.stringTypeTable = tInfo.typeTables[reflect.TypeOf("")]
	tInfo.fieldTypeTable = tInfo.typeTables[reflect.TypeOf((*ast.Field)(nil)).Elem()]
	return tInfo
}

var _TYPE_INFO typeInfo = makeTypeInfo()

func makeGoalRef(value interface{}) goalRef {
	return goalRef {_TYPE_INFO.typeTables[reflect.TypeOf(value)], value}
}

func makeStrRef(value interface{}) goalRef {
	return goalRef {_TYPE_INFO.stringTypeTable, value}
}

func (bc *BytecodeExecContext) resolveSpecialMember(objIdx int, memberIdx int) goalRef {
	n := bc.Stack[objIdx]

	if n.value == nil {
		return makeStrRef("")
	}

	switch node := n.value.(type) {
	case *ast.FuncDecl:
		if memberIdx == SMEMBER_type {
			return makeStrRef(bc.ExprRepr(node.Type))
		} else if memberIdx == SMEMBER_name {
			return makeStrRef(node.Name.Name)
		} else if memberIdx == SMEMBER_receiver {
			if node.Recv == nil {
				return goalRef{_TYPE_INFO.fieldTypeTable, nil}
			}
			return goalRef{_TYPE_INFO.fieldTypeTable, node.Recv.List[0]}
		}
	case *ast.Field:
		if memberIdx == SMEMBER_type {
			return makeStrRef(bc.ExprRepr(node.Type))
		} else if memberIdx == SMEMBER_name {
			return makeStrRef(node.Names[0].Name)
		}
	case *ast.TypeSpec:
		if memberIdx == SMEMBER_type {
			return makeStrRef(bc.ExprRepr(node.Type))
		} else if memberIdx == SMEMBER_name {
			return makeStrRef(node.Name.Name)
		}
	}
	if memberIdx == SMEMBER_location {
		return makeStrRef(bc.PositionString(n.value.(ast.Node)))
	}
	panic("resolveStringMember received unknown memberIdx " + strconv.Itoa(memberIdx) + " for " + reflect.TypeOf(n).String())
}

func (bc *BytecodeExecContext) resolveObjectMember(objIdx int, memberIdx int) goalRef {
	ref := bc.Stack[objIdx]
	idx := ref.memberIndices[memberIdx]
	typ := ref.memberTypes[memberIdx]
	return goalRef{typ, reflect.ValueOf(ref.value).FieldByIndex(idx).Interface()}
}
