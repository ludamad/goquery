package goal

import "fmt"
import "reflect"

func (bc *BytecodeContext) sprintN(n int) string {
	fmtString := bc.peek(n).Value.(string)
	var str string
	if n == 1 {
		str = fmtString
	} else {
		args := bc.Stack[len(bc.Stack)-(n-1):]
		// Helper to coerce []string -> ...interface{} (via ...string)
		iargs := make([]interface{}, len(args))
		for i := range args {
			iargs[i] = args[i].Value
		}
		str = fmt.Sprintf(fmtString, iargs...)
	}
	bc.popN(n)
	return str
}

type BytecodeExecContext struct {
	*BytecodeContext
	*GlobalSymbolContext
	*FileSymbolContext
}

func isTrueValue(val interface{}) bool {
	return (val == nil || val == false || val == "");
}

func (bc BytecodeExecContext) resolveUnaryOp(id int, val goalRef) goalRef {
	switch id {
		case UNARY_OP_NOT: return makeBoolRef(!isTrueValue(val)) 
		case UNARY_OP_LEN: return makeIntRef(reflect.ValueOf(val.Value).Len())  
	}
	panic("Unexpected unary op")
}

func (bc BytecodeExecContext) resolveBinOp(id int, val1 goalRef, val2 goalRef) goalRef {
	switch id {
		case BIN_OP_AND: if !isTrueValue(val1.Value) { return val1 } else {return val2 }
		case BIN_OP_OR: if isTrueValue(val1.Value) { return val1 } else {return val2 }
		case BIN_OP_XOR: if isTrueValue(val1.Value) != isTrueValue(val2.Value) { return makeBoolRef(true) } else {makeBoolRef(false) }
		case BIN_OP_TYPECHECK: if resolveType(val2.Value) == val1.Value.(reflect.Type) { return makeBoolRef(true) } else {return makeBoolRef(false) }
		case BIN_OP_INDEX: return makeGoalRef(reflect.ValueOf(val1.Value).Index(val2.Value.(int)).Interface())
		case BIN_OP_CONCAT: return makeStrRef(val1.Value.(string) + val2.Value.(string))
		case BIN_OP_EQUAL: return makeBoolRef(val1.Value == val2.Value)
	}
	panic("Unexpected bin op")
}

func dumpStack(refs []goalRef) {
	for i,ref := range refs {
		if ref.Value == nil {
			fmt.Printf("\t%d) nil\n", i) } else {
			fmt.Printf("\t%d) %s\n", i, resolveType(ref.Value).Name())
		}
	}
}

func (bc BytecodeExecContext) execOne() {
	code := bc.Bytecodes[bc.Index]
	bc.Index++
	switch code.Code {
	case BC_CONSTANT:
		bc.push(bc.Constants[code.Bytes1to3()])
	case BC_SPECIAL_PUSH:
		str := bc.resolveSpecialMember(code.Bytes1to2(), int(code.Val3))
		bc.push(str)
	case BC_MEMBER_PUSH:
		obj := bc.resolveObjectMember(code.Bytes1to2(), int(code.Val3))
		bc.push(obj)
	case BC_PUSH:
		obj := bc.Stack[code.Bytes1to3()]
		bc.push(obj)
	case BC_PUSH_NIL:
		bc.push(makeStrRef(nil))
	case BC_POPN:
		bc.popN(code.Bytes1to3())
	case BC_NEXT:
		obj,idxObj,idx := bc.peek(2), bc.peek(1),0
		if idxObj.Value != nil {
			idx = idxObj.Value.(int)
		}
		bc.popN(1) ; val := reflect.ValueOf(obj.Value)
		if val.Type().Kind() != reflect.Slice {
			panic("Can only iterate over slices!")
		}
		if val.Len() <= idx {
			bc.popN(1)
			bc.Index = code.Bytes1to3()
		} else {
			bc.push(makeIntRef(idx+1))
			bc.push(makeGoalRef(val.Index(idx).Interface()))
		}
	case BC_CONCATN:
		bc.concatStrings(code.Bytes1to3())
	case BC_SAVE_TUPLE:
		n := int(code.Val3)
		bc.SaveData(bc.DatabaseContext, code.Bytes1to2(), bc.copyStackObjects(n))
		bc.popN(n)
	case BC_JMP_FALSE:
		if isTrueValue(bc.peek(1).Value) {
			bc.Index = code.Bytes1to3()
		}
		bc.popN(1)
	case BC_BIN_OP:
		obj := bc.resolveBinOp(code.Bytes1to3(), bc.peek(2), bc.peek(1))
		bc.popN(2);
		bc.push(obj)
	case BC_UNARY_OP:
		obj := bc.resolveUnaryOp(code.Bytes1to3(), bc.peek(1))
		bc.popN(1);
		bc.push(obj)
	case BC_JMP:
		bc.Index = code.Bytes1to3()
	case BC_PRINTFN:
		n := code.Bytes1to3()
		fmt.Print(bc.sprintN(n))
	case BC_SPRINTFN:
		n := code.Bytes1to3()
		bc.push(makeStrRef(bc.sprintN(n)))
	default:
		panic("Bad bytes!")
	}
}

func (bc *BytecodeContext) Exec(globSym *GlobalSymbolContext, fileSym *FileSymbolContext, objects []interface{}) {
	// Reset
	bc.Index = 0
	bc.popN(len(bc.Stack))

	for _, obj := range objects {
		bc.push(makeGoalRef(obj))
	}

	bcExecContext := BytecodeExecContext{bc, globSym, fileSym}
	for bc.Index < len(bc.Bytecodes) {
		bcExecContext.execOne()
	}

	bc.popN(len(objects))
}
