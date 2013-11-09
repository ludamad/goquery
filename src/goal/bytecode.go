package goal

import (
	"bytes"
)

type BytecodeContext struct {
	Bytecodes []Bytecode
	Constants []goalRef
}

type BytecodeObjectStack struct {
	BaseIndex int
	Stack     []goalRef
}

type BytecodeExecContext struct {
	*BytecodeContext
	*GlobalSymbolContext
	*FileSymbolContext
	*BytecodeObjectStack
	Index     int // Instruction pointer
}

func NewBytecodeContext() *BytecodeContext {
	return &BytecodeContext{[]Bytecode{}, []goalRef{}}
}

func (bc *BytecodeExecContext) copyStackObjects(num int) []interface{} {
	tuple := make([]interface{}, num)
	for i, v := range bc.Stack[len(bc.Stack)-num:] {
		tuple[i] = v.Value
	}
	return tuple
}

func (bc *BytecodeExecContext) concatStrings(num int) {
	top := len(bc.Stack)
	b := bytes.NewBufferString("")
	for i := top - num; i < top; i++ {
		b.WriteString(bc.Stack[i].Value.(string))
	}
	bc.PopN(num)
	bc.Push(makeStrRef(b.String()))
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

func (bc *BytecodeObjectStack) Push(obj goalRef) {
	bc.Stack = append(bc.Stack, obj)
}

func (bc *BytecodeObjectStack) Get(idx int) goalRef {
	return bc.Stack[bc.BaseIndex + idx]
}

func (bc *BytecodeObjectStack) Peek(idx int) goalRef {
	return bc.Stack[len(bc.Stack)-idx]
}

func (bc *BytecodeObjectStack) PopN(num int) {
	bc.Stack = bc.Stack[:len(bc.Stack)-num]
}
