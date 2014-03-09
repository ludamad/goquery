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

func (bc Bytecode) Bytes1to2() int {
	return bytes2int(bc.Val1, bc.Val2)
}

func (bc Bytecode) Bytes2to3() int {
	return bytes2int(bc.Val2, bc.Val3)
}

func (bc Bytecode) Bytes1to3() int {
	return bytes3int(bc.Val1, bc.Val2, bc.Val3)
}

const (
	BC_CONSTANT = iota // Pushes an object constant
	BC_PUSH // Pushes the object at the given stack index to the top of the stack
	BC_PUSH_NIL
	BC_MEMBER_PUSH // Takes <object> <member name>
	BC_SPECIAL_PUSH // Takes <object> <special member name: 'name', 'location' or 'type'>
	BC_POPN // Takes <number>, pops that many objects from the stack.
	BC_CONCATN
	BC_RETURN // Signals that a value was returned (the value at the top of the stack)
	BC_NEXT // Takes <code index>, expects [object, key], leaves [object, next key, next value] on stack.
	// If there is no next key, pops [object, key] and jumps to the code index.
	BC_SAVE_TUPLE // Takes <tuple kind>, <tuple size>, pops tuple data from the stack
	BC_JMP_FALSE // Takes <code index>, jumps if the top element is: "", false, or nil. Pops the top element
	BC_JMP // Takes <code index>, jumps unconditionally
	BC_BIN_OP // Performs binary operation <id>. Pops both operands, pushes result
	BC_UNARY_OP // Performs unary operation <id>. Pops operands, pushes result
	BC_PRINTFN // Takes <N>, first string is treated as format specifier, pops N, prints string
	BC_SPRINTFN // Takes <N>, first string is treated as format specifier, pops N, pushes string
	BC_PUSH_PARENT // Takes <N>, where N=1 is the immediate parent, N=2 the parent's parent, etc
	BC_PUSH_CHILD_NUM // Takes no arguments, pushes the node's child number
	BC_RESET_CHILD_NUM // Resets the child enumeration to 0
	BC_PUSH_NODE_DEPTH // Takes no arguments, pushes the node's depth
	BC_CALLN
	BC_EXECN
)

const (
	BIN_OP_AND = iota // Evaluates an object-oriented 'and'
	BIN_OP_OR // Evaluates an object-oriented 'or'
	BIN_OP_XOR // Evaluates a 'xor
	BIN_OP_INDEX // Evaluates a slice-index
	BIN_OP_CONCAT
	BIN_OP_TYPECHECK
	BIN_OP_EQUAL
	BIN_OP_REPEAT
)

const (
	UNARY_OP_NOT = iota // Evaluates a 'not' of the top element, pops it, pushes result
	UNARY_OP_LEN
	UNARY_OP_GETID
)

// Special members
const (
	SMEMBER_location = iota
	SMEMBER_pos
	SMEMBER_type
	SMEMBER_name
	SMEMBER_receiver
)