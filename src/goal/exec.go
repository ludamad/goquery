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
	fmtString := bc.peekString(n)
	if n == 1 {
		fmt.Print(fmtString)
	} else {
		args := bc.sliceStrings(n - 1)
		// Helper to coerce []string -> ...interface{} (via ...string)
		iargs := make([]interface{}, len(args))
		for i := range args {
			iargs[i] = args[i]
		}
		fmt.Printf(fmtString, iargs...)
	}
	bc.popStrings(n)
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
	case BC_STRING_CONSTANT:
		bc.pushString(bc.StringConstants[code.bytes1to3()])
	case BC_STRING_PUSH:
		str := bc.resolveStringMember(code.bytes1to2(), int(code.Val3))
		bc.pushString(str)
	case BC_OBJECT_PUSH:
		obj := bc.resolveObjectMember(code.bytes1to2(), int(code.Val3))
		bc.pushObject(obj)
	case BC_POP_STRINGSN:
		bc.popStrings(code.bytes1to3())
	case BC_POP_OBJECTSN:
		bc.popObjects(code.bytes1to3())
	case BC_LOOP_PUSH:
		bc.pushLoop(bc.resolveLoop(code.bytes1to2(), int(code.Val3)))
		bc.tryLoop(false)
	case BC_LOOP_CONTINUE:
		bc.tryLoop(true)
	case BC_CONCATN:
		bc.concatStrings(code.bytes1to3())
	case BC_SAVE_TUPLE:
		n := int(code.Val3)
		bc.SaveTuple(code.bytes1to2(), bc.copyStrings(n))
		bc.popStrings(n)
	case BC_LOAD_TUPLE:
		n := int(code.Val3)
		tuple := bc.LoadTuple(code.bytes1to2(), bc.sliceStrings(n))
		bc.popStrings(n)
		if len(tuple) == 0 {
			bc.pushObject(nil)
		} else {
			bc.pushObject(tuple)
		}
	case BC_MAKE_TUPLE:
		n := code.bytes1to3()
		bc.pushObject(bc.copyStrings(n))
		bc.popStrings(n)
	case BC_JMP_STR_ISEMPTY:
		if bc.peekString(1) == "" {
			bc.Index = code.bytes1to3()
		}
		bc.popStrings(1)
	case BC_JMP_OBJ_ISNIL:
		if bc.peekObject(1) == nil {
			bc.Index = code.bytes1to3()
		}
	case BC_JMP:
		bc.Index = code.bytes1to3()
	case BC_PRINTFN:
		n := code.bytes1to3()
		bc.printN(n)
	default:
		panic("Bad bytes!")
	}
}

func (bc *BytecodeContext) Exec(globSym *GlobalSymbolContext, fileSym *FileSymbolContext, objects []interface{}) {
	// Reset
	bc.Index = 0
	bc.popObjects(len(bc.ObjectStack))
	bc.popStrings(len(bc.StringStack))

	for _, obj := range objects {
		bc.pushObject(obj)
	}

	bcExecContext := BytecodeExecContext{bc, globSym, fileSym}
	for bc.Index < len(bc.Bytecodes) {
		bcExecContext.execOne()
	}


	bc.popObjects(len(objects))
}
