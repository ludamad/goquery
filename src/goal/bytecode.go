package goal

import (
	"bytes"
)

type LoopController interface {
	Enter(bc *BytecodeContext) bool
	Exit(bc *BytecodeContext)
}

type LoopContext struct {
	Controller LoopController
	StartIndex int
}

type BytecodeContext struct {
	Bytecodes       []Bytecode
	Index           int // Instruction pointer
	StringStack     []string
	ObjectStack     []interface{}
	StringConstants []string
	LoopStack       []LoopContext
}

func NewBytecodeContext() *BytecodeContext {
	return &BytecodeContext{[]Bytecode{}, 0, []string{}, []interface{}{}, []string{}, []LoopContext{}}
}

func (bc *BytecodeContext) pushString(str string) {
	bc.StringStack = append(bc.StringStack, str)
}

func (bc *BytecodeContext) peekString(idx int) string {
	return bc.StringStack[len(bc.StringStack)-idx]
}

func (bc *BytecodeContext) popStrings(num int) {
	bc.StringStack = bc.StringStack[:len(bc.StringStack)-num]
}

func (bc *BytecodeContext) sliceStrings(num int) []string {
	return bc.StringStack[len(bc.StringStack)-num:]
}

func (bc *BytecodeContext) copyStrings(num int) []string {
	tuple := make([]string, num)
	copy(tuple, bc.sliceStrings(num))
	return tuple
}

func (bc *BytecodeContext) concatStrings(num int) {
	top := len(bc.StringStack)
	b := bytes.NewBufferString("")
	for i := top - num; i < top; i++ {
		b.WriteString(bc.StringStack[i])
	}
	bc.popStrings(num)
	bc.pushString(b.String())
}

func (bc *BytecodeContext) PushStringConstant(constant string) {
	bc.StringConstants = append(bc.StringConstants, constant)
}

func (bc *BytecodeContext) PushBytecode(code Bytecode) {
	bc.Bytecodes = append(bc.Bytecodes, code)
}

func (bc *BytecodeContext) pushLoop(loop LoopContext) {
	bc.LoopStack = append(bc.LoopStack, loop)
}

func (bc *BytecodeContext) popLoop() {
	bc.LoopStack = bc.LoopStack[:len(bc.LoopStack)-1]
}

func (bc *BytecodeContext) pushObject(obj interface{}) {
	bc.ObjectStack = append(bc.ObjectStack, obj)
}

func (bc *BytecodeContext) peekObject(idx int) interface{} {
	return bc.ObjectStack[len(bc.ObjectStack)-idx]
}

func (bc *BytecodeContext) popObjects(num int) {
	bc.ObjectStack = bc.ObjectStack[:len(bc.ObjectStack)-num]
}
