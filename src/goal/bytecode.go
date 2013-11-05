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
	Stack     []goalRef
	Constants []goalRef
	LoopStack []LoopContext
}

func NewBytecodeContext() *BytecodeContext {
	return &BytecodeContext{[]Bytecode{}, 0, []goalRef{}, []goalRef{}, []LoopContext{}}
}

func (bc *BytecodeContext) copyStrings(num int) []string {
	tuple := make([]string, num)
	for i, v := range bc.Stack[len(bc.Stack)-num:] {
		tuple[i] = v.Value.(string)
	}
	return tuple
}

func (bc *BytecodeContext) concatStrings(num int) {
	top := len(bc.Stack)
	b := bytes.NewBufferString("")
	for i := top - num; i < top; i++ {
		b.WriteString(bc.Stack[i].Value.(string))
	}
	bc.popN(num)
	bc.push(makeStrRef(b.String()))
}

func (bc *BytecodeContext) PushConstant(constant interface{}) {
	float, ok := constant.(float64)
	if ok {
		bc.Constants = append(bc.Constants, makeGoalRef(int(float)))
	} else {
		bc.Constants = append(bc.Constants, makeGoalRef(constant))
	}
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

func (bc *BytecodeContext) push(obj goalRef) {
	bc.Stack = append(bc.Stack, obj)
}

func (bc *BytecodeContext) peek(idx int) goalRef {
	return bc.Stack[len(bc.Stack)-idx]
}

func (bc *BytecodeContext) popN(num int) {
	bc.Stack = bc.Stack[:len(bc.Stack)-num]
}
