package goal

import (
	"bytes"
)

type BytecodeContext struct {
	Bytecodes []Bytecode
	Constants []goalRef
}

type goalStack []goalRef

type BytecodeExecContext struct {
	*BytecodeContext
	*GlobalSymbolContext
	*FileSymbolContext
	*goalStack
	parentChain nodeParentChain
	BaseStackIndex int
	Index     int // Instruction pointer
}

func NewBytecodeContext() *BytecodeContext {
	return &BytecodeContext{[]Bytecode{}, []goalRef{}}
}

func (gs *goalStack) copyStackObjects(num int) []interface{} {
	tuple := make([]interface{}, num)
	for i, v := range (*gs)[len(*gs)-num:] {
		tuple[i] = v.Value
	}
	return tuple
}

func (bc *BytecodeExecContext) concatStrings(num int) {
	top := len(*bc.goalStack)
	b := bytes.NewBufferString("")
	for i := top - num; i < top; i++ {
		b.WriteString(bc.RawGet(i).Value.(string))
	}
	bc.PopN(num)
	bc.Push(makeStrRef(b.String()))
}

// For Lua interaction:
func (bc *BytecodeContext) PushConstantI(integer int) {
	bc.PushConstant(integer)
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

func (gs *goalStack) Push(obj goalRef) {
	*gs = append(*gs, obj)
}

func (bc *BytecodeExecContext) Get(idx int) goalRef {
	return bc.RawGet(bc.BaseStackIndex + idx)
}

func (gs *goalStack) Peek(idx int) goalRef {
	return (*gs)[len(*gs)-idx]
}

func (gs *goalStack) RawGet(idx int) goalRef {
	return (*gs)[idx]
}

func (gs *goalStack) PopN(num int) {
	*gs = (*gs)[:len(*gs)-num]
}
