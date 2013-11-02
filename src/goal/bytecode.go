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
	Bytecodes []Bytecode
	Index     int // Instruction pointer
	Stack     []interface{}
	Constants []interface{}
	LoopStack []LoopContext
}

func NewBytecodeContext() *BytecodeContext {
	return &BytecodeContext{[]Bytecode{}, 0, []interface{}{}, []interface{}{}, []LoopContext{}}
}

func (bc *BytecodeContext) copyStrings(num int) []string {
	tuple := make([]string, num)
	for i, v := range bc.Stack[len(bc.Stack)-num:] {
		tuple[i] = v.(string)
	}
	return tuple
}

func (bc *BytecodeContext) concatStrings(num int) {
	top := len(bc.Stack)
	b := bytes.NewBufferString("")
	for i := top - num; i < top; i++ {
		b.WriteString(bc.Stack[i].(string))
	}
	bc.popN(num)
	bc.push(b.String())
}

func (bc *BytecodeContext) PushConstant(constant interface{}) {
	bc.Constants = append(bc.Constants, constant)
}

func (bc *BytecodeContext) PushBytecode(code Bytecode) int {
	bc.Bytecodes = append(bc.Bytecodes, code)
	return len(bc.Bytecodes) - 1 // Return new index
}

func (bc *BytecodeContext) BytecodeSize() int {
	return len(bc.Bytecodes)
}

func (bc *BytecodeContext) SetBytecode(index int, code Bytecode) {
	bc.Bytecodes[index] = code
}

func (bc *BytecodeContext) pushLoop(loop LoopContext) {
	bc.LoopStack = append(bc.LoopStack, loop)
}

func (bc *BytecodeContext) popLoop() {
	bc.LoopStack = bc.LoopStack[:len(bc.LoopStack)-1]
}

func (bc *BytecodeContext) push(obj interface{}) {
	bc.Stack = append(bc.Stack, obj)
}

func (bc *BytecodeContext) peek(idx int) interface{} {
	return bc.Stack[len(bc.Stack)-idx]
}

func (bc *BytecodeContext) popN(num int) {
	bc.Stack = bc.Stack[:len(bc.Stack)-num]
}
