package goal

type Bytecode struct {
	Code             byte
	Val1, Val2, Val3 byte
}

func bytes2int(b1, b2 byte) int {
	return int(b1) + (int(b2) * 256)
}

func bytes3int(b1, b2, b3 byte) int {
	return bytes2int(b1, b2) + int(b3)*65536
}

func (bc Bytecode) bytes1to2() int {
	return bytes2int(bc.Val1, bc.Val2)
}

func (bc Bytecode) bytes2to3() int {
	return bytes2int(bc.Val2, bc.Val3)
}

func (bc Bytecode) bytes1to3() int {
	return bytes3int(bc.Val1, bc.Val2, bc.Val3)
}

const (
	BC_STRING_PUSH = iota // Takes <object> <member string>, always pushes a single string.
	BC_STRING_CONSTANT // Pushes a string constant
	BC_OBJECT_PUSH // Takes <object> <member object>
	BC_LOOP_PUSH
	BC_LOOP_CONTINUE
	BC_POP_STRINGSN // Takes <number>, pops that many strings from the stack.
	BC_POP_OBJECTSN // Takes <number>, pops that many strings from the stack.
	BC_CONCATN
	BC_SAVE_TUPLE // Takes <tuple kind>, <tuple size>, pops tuple data from string stack
	BC_LOAD_TUPLE // Takes <tuple kind>, <key size>, pushes tuple to object stack
	BC_MAKE_TUPLE // Takes <key size>, pushes a tuple (string vector) onto the object stack
	BC_TUPLE_STRING_PUSH // Takes <object index>, pushes a string from the tuple onto the string stack
	BC_JMP_STR_ISEMPTY // Takes <code index>, jumps if the top string index is nil
	BC_JMP_OBJ_ISNIL // Takes <code index>, jumps if the top object index is nil
	BC_JMP // Takes <code index>, jumps unconditionally
	BC_PRINTFN // Takes <N>, first string is treated as format specifier
)

// Object members
const (
	OMEMBER_Signature = iota
	OMEMBER_Receiver
)

// Loopable members
const (
	LMEMBER_Methods = iota
)

// String members
const (
	SMEMBER_location = iota
	SMEMBER_type
	SMEMBER_name
)