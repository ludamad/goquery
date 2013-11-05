package goal

import (
	"go/ast"
	"reflect"
	"strconv"
	"fmt"
)

type typeTable struct {
	name string
	memberTypes   []*typeTable
	memberIndices [][]int
}

type goalRef struct {
	*typeTable
	Value interface{}
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
	stringTypeTable  *typeTable
	boolTypeTable  *typeTable
	fieldTypeTable   *typeTable
	intTypeTable   *typeTable
	TypeMembers      []string
	stringToMemberId map[string]int
	NameToType map[string]reflect.Type
}

func makeTypeInfo() typeInfo {
	// If it makes you feel any better, the following code wasn't handwritten.
	types := []reflect.Type{
		reflect.TypeOf(""),
		reflect.TypeOf(1),
		reflect.TypeOf((*ast.ArrayType)(nil)).Elem(),
		reflect.TypeOf((*ast.AssignStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.BadDecl)(nil)).Elem(),
		reflect.TypeOf((*ast.BadExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.BadStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.BasicLit)(nil)).Elem(),
		reflect.TypeOf((*ast.BinaryExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.BlockStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.BranchStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.CallExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.CaseClause)(nil)).Elem(),
		reflect.TypeOf((*ast.ChanDir)(nil)).Elem(),
		reflect.TypeOf((*ast.ChanType)(nil)).Elem(),
		reflect.TypeOf((*ast.CommClause)(nil)).Elem(),
		reflect.TypeOf((*ast.Comment)(nil)).Elem(),
		reflect.TypeOf((*ast.CommentGroup)(nil)).Elem(),
		reflect.TypeOf((*ast.CommentMap)(nil)).Elem(),
		reflect.TypeOf((*ast.CompositeLit)(nil)).Elem(),
		reflect.TypeOf((*ast.Decl)(nil)).Elem(),
		reflect.TypeOf((*ast.DeclStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.DeferStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.Ellipsis)(nil)).Elem(),
		reflect.TypeOf((*ast.EmptyStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.ExprStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.Field)(nil)).Elem(),
		reflect.TypeOf((*ast.FieldFilter)(nil)).Elem(),
		reflect.TypeOf((*ast.FieldList)(nil)).Elem(),
		reflect.TypeOf((*ast.File)(nil)).Elem(),
		reflect.TypeOf((*ast.Filter)(nil)).Elem(),
		reflect.TypeOf((*ast.ForStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.FuncDecl)(nil)).Elem(),
		reflect.TypeOf((*ast.FuncLit)(nil)).Elem(),
		reflect.TypeOf((*ast.FuncType)(nil)).Elem(),
		reflect.TypeOf((*ast.GenDecl)(nil)).Elem(),
		reflect.TypeOf((*ast.GoStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.Ident)(nil)).Elem(),
		reflect.TypeOf((*ast.IfStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.ImportSpec)(nil)).Elem(),
		reflect.TypeOf((*ast.Importer)(nil)).Elem(),
		reflect.TypeOf((*ast.IncDecStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.IndexExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.InterfaceType)(nil)).Elem(),
		reflect.TypeOf((*ast.KeyValueExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.LabeledStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.MapType)(nil)).Elem(),
		reflect.TypeOf((*ast.MergeMode)(nil)).Elem(),
		reflect.TypeOf((*ast.ObjKind)(nil)).Elem(),
		reflect.TypeOf((*ast.Object)(nil)).Elem(),
		reflect.TypeOf((*ast.Package)(nil)).Elem(),
		reflect.TypeOf((*ast.ParenExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.RangeStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.ReturnStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.Scope)(nil)).Elem(),
		reflect.TypeOf((*ast.SelectStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.SelectorExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.SendStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.SliceExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.StarExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.StructType)(nil)).Elem(),
		reflect.TypeOf((*ast.SwitchStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.TypeAssertExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.TypeSpec)(nil)).Elem(),
		reflect.TypeOf((*ast.TypeSwitchStmt)(nil)).Elem(),
		reflect.TypeOf((*ast.UnaryExpr)(nil)).Elem(),
		reflect.TypeOf((*ast.ValueSpec)(nil)).Elem(),
	}
	tables := map[reflect.Type]*typeTable{}
	tInfo := typeInfo{tables, nil, nil, nil, nil, []string{}, map[string]int{}, map[string]reflect.Type{}}
	members := map[string]bool{}
	for _, typ := range types {
		tInfo.NameToType[typ.Name()] = typ
		fillMemberNames(typ, members)
	}
	for member, _ := range members {
		tInfo.stringToMemberId[member] = len(tInfo.TypeMembers)
		tInfo.TypeMembers = append(tInfo.TypeMembers, member)
	}
	for _, typ := range types {
		tables[typ] = &typeTable{typ.Name(), []*typeTable{}, [][]int{}}
	}
	for _, typ := range types {
		makeTypeTable(&tInfo, typ)
	}
	tInfo.stringTypeTable = tInfo.typeTables[reflect.TypeOf("")]
	tInfo.fieldTypeTable = tInfo.typeTables[reflect.TypeOf((*ast.Field)(nil)).Elem()]
	tInfo.boolTypeTable = tInfo.typeTables[reflect.TypeOf(true)]
	tInfo.intTypeTable = tInfo.typeTables[reflect.TypeOf(1)]
	return tInfo
}

var _TYPE_INFO typeInfo = makeTypeInfo()

func resolveType(value interface{}) reflect.Type {
	typ := reflect.TypeOf(value)
	if typ.Kind() == reflect.Ptr {
		return typ.Elem()
	} else {
		return typ
	}
}

func makeGoalRef(value interface{}) goalRef {
	return goalRef{_TYPE_INFO.typeTables[resolveType(value)], value}
}

func makeStrRef(value interface{}) goalRef {
	return goalRef{_TYPE_INFO.stringTypeTable, value}
}

func makeBoolRef(value interface{}) goalRef {
	return goalRef{_TYPE_INFO.boolTypeTable, value}
}
func makeIntRef(value interface{}) goalRef {
	return goalRef{_TYPE_INFO.intTypeTable, value}
}

func (bc *BytecodeExecContext) resolveSpecialMember(objIdx int, memberIdx int) goalRef {
	n := bc.Stack[objIdx]

	if n.Value == nil {
		return makeStrRef("")
	}

	switch node := n.Value.(type) {
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
		return makeStrRef(bc.PositionString(n.Value.(ast.Node)))
	}
	panic("resolveSpecialMember received unknown memberIdx " + strconv.Itoa(memberIdx) + " for " + reflect.TypeOf(n.Value).String())
}

func (bc *BytecodeExecContext) resolveObjectMember(objIdx int, memberIdx int) goalRef {
	ref := bc.Stack[objIdx]
	if ref.Value != nil && ref.typeTable == nil {
		ref.typeTable = _TYPE_INFO.typeTables[resolveType(ref.Value)]
	}
	if len(ref.memberIndices) == 0 {
		fmt.Printf("%s\n", ref.typeTable.name)
		return makeStrRef(nil)
	}
	idx := ref.memberIndices[memberIdx]
	typ := ref.memberTypes[memberIdx]
	return goalRef{typ, reflect.Indirect(reflect.ValueOf(ref.Value)).FieldByIndex(idx).Interface()}
}
 