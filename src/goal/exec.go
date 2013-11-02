package goal

import "fmt"

func (bc *BytecodeContext) scanForLoopEnd(start int) int {
	for i := start; i < len(bc.Bytecodes); i++ {
		if bc.Bytecodes[i].Code == BC_LOOP_CONTINUE {
			return i
		}
	}
	panic("scanForLoopEnd could not find end!")
}

func (bc *BytecodeContext) tryLoop(hasStarted bool) {
	loop := bc.LoopStack[len(bc.LoopStack)-1]
	if loop.Controller.Enter(bc) {
		// Loop was entered, go to start index
		bc.Index = loop.StartIndex
	} else {
		if hasStarted {
			// Already at end, clean up stacks
			loop.Controller.Exit(bc)
		} else {
			// Stacks already clean, jump to end
			bc.Index = bc.scanForLoopEnd(loop.StartIndex)
		}
	}
}

func (bc *BytecodeContext) printN(n int) {
	fmtString := bc.peek(n).(string)
	if n == 1 {
		fmt.Print(fmtString)
	} else {
		args := bc.copyStrings(n - 1)
		// Helper to coerce []string -> ...interface{} (via ...string)
		iargs := make([]interface{}, len(args))
		for i := range args {
			iargs[i] = args[i]
		}
		fmt.Printf(fmtString, iargs...)
	}
	bc.popN(n)
}

type BytecodeExecContext struct {
	*BytecodeContext
	*GlobalSymbolContext
	*FileSymbolContext
}

func (bc BytecodeExecContext) execOne() {
	code := bc.Bytecodes[bc.Index]
	bc.Index++
	switch code.Code {
	case BC_CONSTANT:
		bc.push(bc.Constants[code.Bytes1to3()])
	case BC_SPECIAL_PUSH:
		str := bc.resolveStringMember(code.Bytes1to2(), int(code.Val3))
		bc.push(str)
	case BC_MEMBER_PUSH:
		obj := bc.resolveObjectMember(code.Bytes1to2(), int(code.Val3))
		bc.push(obj)
	case BC_PUSH:
		obj := bc.Stack[code.Bytes1to3()]
		bc.push(obj)
	case BC_POPN:
		bc.popN(code.Bytes1to3())
	case BC_LOOP_PUSH:
		bc.pushLoop(bc.resolveLoop(code.Bytes1to2(), int(code.Val3)))
		bc.tryLoop(false)
	case BC_LOOP_CONTINUE:
		bc.tryLoop(true)
	case BC_CONCATN:
		bc.concatStrings(code.Bytes1to3())
	case BC_SAVE_TUPLE:
		n := int(code.Val3)
		bc.SaveTuple(code.Bytes1to2(), bc.copyStrings(n))
		bc.popN(n)
	case BC_LOAD_TUPLE:
		n := int(code.Val3)
		tuple := bc.LoadTuple(code.Bytes1to2(), bc.copyStrings(n))
		bc.popN(n)
		if len(tuple) == 0 {
			bc.push(nil)
		} else {
			bc.push(tuple)
		}
	case BC_MAKE_TUPLE:
		n := code.Bytes1to3()
		bc.push(bc.copyStrings(n))
		bc.popN(n)
	case BC_JMP_FALSE:
		topVal := bc.peek(1)
		if topVal == nil || topVal == false || topVal == ""  {
			bc.Index = code.Bytes1to3()
		}
		bc.popN(1)
	case BC_BOOL_AND: // Evaluates an object-oriented 'and' of the top two elements, pops both, pushes result
		panic("TODO")
	case BC_BOOL_OR: // Evaluates an object-oriented 'or' of the top two elements, pops both, pushes result
		panic("TODO")
	case BC_BOOL_XOR: // Evaluates a 'xor' of the top two elements, pops both, pushes result
		panic("TODO")
	case BC_BOOL_NOT: // Evaluates a 'not' of the top element, pops it, pushes result
		panic("TODO")
	case BC_JMP:
		bc.Index = code.Bytes1to3()
	case BC_PRINTFN:
		n := code.Bytes1to3()
		bc.printN(n)
	default:
		panic("Bad bytes!")
	}
}

func (bc *BytecodeContext) Exec(globSym *GlobalSymbolContext, fileSym *FileSymbolContext, objects []interface{}) {
	// Reset
	bc.Index = 0
	bc.popN(len(bc.Stack))

	for _, obj := range objects {
		bc.push(obj)
	}

	bcExecContext := BytecodeExecContext{bc, globSym, fileSym}
	for bc.Index < len(bc.Bytecodes) {
		bcExecContext.execOne()
	}

	bc.popN(len(objects))
}
