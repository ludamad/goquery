package goal

import "fmt"
import "reflect"

func (bc *BytecodeExecContext) sprintN(n int) string {
	fmtString := bc.Peek(n).Value.(string)
	var str string
	if n == 1 {
		str = fmtString
	} else {
		args := (*bc.goalStack)[len(*bc.goalStack)-(n-1):]
		// Helper to coerce []string -> ...interface{} (via ...string)
		iargs := make([]interface{}, len(args))
		for i := range args {
			iargs[i] = args[i].Value
		}
		str = fmt.Sprintf(fmtString, iargs...)
	}
	bc.PopN(n)
	return str
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
		case BIN_OP_REPEAT: 
			str := val1.Value.(string)
			num := val2.Value.(int)
			result := ""
			for i := 0; i < num; i++ {
				result += str
			}
			return makeStrRef(result)
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

func (bc *BytecodeExecContext) execOne() bool {
	code := bc.Bytecodes[bc.Index]
	bc.Index++
	switch code.Code {
	case BC_CONSTANT:
		bc.Push(bc.Constants[code.Bytes1to3()])
	case BC_SPECIAL_PUSH:
		str := bc.resolveSpecialMember(code.Bytes1to2(), int(code.Val3))
		bc.Push(str)
	case BC_MEMBER_PUSH:
		obj := bc.resolveObjectMember(code.Bytes1to2(), int(code.Val3))
		bc.Push(obj)
	case BC_PUSH:
		obj := bc.Get(code.Bytes1to3())
		bc.Push(obj)
	case BC_PUSH_NIL:
		bc.Push(makeStrRef(nil))
	case BC_POPN:
		bc.PopN(code.Bytes1to3())
	case BC_NEXT:
		obj,idxObj,idx := bc.Peek(2), bc.Peek(1),0
		if idxObj.Value != nil {
			idx = idxObj.Value.(int)
		}
		bc.PopN(1) ; val := reflect.ValueOf(obj.Value)
		if val.Type().Kind() != reflect.Slice {
			panic("Can only iterate over slices!")
		}
		if val.Len() <= idx {
			bc.PopN(1)
			bc.Index = code.Bytes1to3()
		} else {
			bc.Push(makeIntRef(idx+1))
			bc.Push(makeGoalRef(val.Index(idx).Interface()))
		}
	case BC_CONCATN:
		bc.concatStrings(code.Bytes1to3())
	case BC_SAVE_TUPLE:
		n := int(code.Val3)
		bc.SaveData(bc.DatabaseContext, code.Bytes1to2(), bc.copyStackObjects(n))
		bc.PopN(n)
	case BC_JMP_FALSE:
		if isTrueValue(bc.Peek(1).Value) {
			bc.Index = code.Bytes1to3()
		}
		bc.PopN(1)
	case BC_BIN_OP:
		obj := bc.resolveBinOp(code.Bytes1to3(), bc.Peek(2), bc.Peek(1))
		bc.PopN(2);
		bc.Push(obj)
	case BC_UNARY_OP:
		obj := bc.resolveUnaryOp(code.Bytes1to3(), bc.Peek(1))
		bc.PopN(1)
		bc.Push(obj)
	case BC_PUSH_PARENT:
		order := code.Bytes1to3()
		par := &bc.parentChain
		// Get 'n'th parent.
		for par.parent != nil && order > 1 {
			par = par.parent
			order -= 1
		}
		bc.Push(makeGoalRef(par.node))
	case BC_PUSH_CHILD_NUM:
		bc.Push(makeGoalRef(bc.parentChain.childNum))
	case BC_PUSH_NODE_DEPTH:
		bc.Push(makeGoalRef(bc.parentChain.depth))
	case BC_JMP:
		bc.Index = code.Bytes1to3()
	case BC_CALLN:
		n := code.Bytes1to3()
		subroutine := bc.Peek(1 + n).Value.(*BytecodeContext)
		bc.call(subroutine, n)
		bc.PopN(n + 1) // Pop the arguments and the bytecode context
	case BC_PRINTFN:
		n := code.Bytes1to3()
		fmt.Print(bc.sprintN(n))
	case BC_SPRINTFN:
		n := code.Bytes1to3()
		bc.Push(makeStrRef(bc.sprintN(n)))
	default:
		panic("Bad bytes!")
	}
	return false // Do not return a value
}

func (bc *BytecodeExecContext) exec() goalRef {
	for bc.Index < len(bc.Bytecodes) {
		if bc.execOne() {
			return bc.Peek(1)
		}
	}
	return makeStrRef(nil)
}

// Call a subroutine, and return a goalRef depending on the return value.
func (bc *BytecodeExecContext) call(subroutine *BytecodeContext, nargs int) goalRef {
	oldLen := len(*bc.goalStack)

	chain := nodeParentChain{nil,nil,0, 0}
	bcCopy := BytecodeExecContext{bc.BytecodeContext, bc.GlobalSymbolContext, bc.FileSymbolContext, bc.goalStack, chain, len(*bc.goalStack) - nargs, 0}
	retVal := bcCopy.exec()
	bc.PopN(len(*bcCopy.goalStack) - oldLen)
	return retVal
}

func (bc *BytecodeContext) ExecNoParent(globSym *GlobalSymbolContext, fileSym *FileSymbolContext, stack *goalStack) {
	chain := nodeParentChain{nil,nil,0, 0}
	bc.Exec(globSym, fileSym, stack, chain)
}

func (bc *BytecodeContext) Exec(globSym *GlobalSymbolContext, fileSym *FileSymbolContext, stack *goalStack, chain nodeParentChain) {
	bcExecContext := BytecodeExecContext{bc, globSym, fileSym, stack, chain, 0, 0}
	bcExecContext.exec()
}
