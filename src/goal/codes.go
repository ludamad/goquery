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
	BC_NEXT // Takes <code index>, expects [object, key], leaves [object, next key, next value] on stack.
	// If there is no next key, pops [object, key] and jumps to the code index.
	BC_SAVE_TUPLE // Takes <tuple kind>, <tuple size>, pops tuple data from the stack
	BC_LOAD_TUPLE // Takes <tuple kind>, <key size>, pushes tuple to stack
	BC_MAKE_TUPLE // Takes <key size>, pushes a tuple (vector) onto the stack
	BC_JMP_FALSE // Takes <code index>, jumps if the top element is: "", false, or nil. Pops the top element
	BC_JMP // Takes <code index>, jumps unconditionally
	BC_BIN_OP // Performs binary operation <id>. Pops both operands, pushes result
	BC_UNARY_OP // Performs unary operation <id>. Pops operands, pushes result
	BC_PRINTFN // Takes <N>, first string is treated as format specifier, pops N, prints string
	BC_SPRINTFN // Takes <N>, first string is treated as format specifier, pops N, pushes string
)

const (
	BIN_OP_AND = iota // Evaluates an object-oriented 'and'
	BIN_OP_OR // Evaluates an object-oriented 'or'
	BIN_OP_XOR // Evaluates a 'xor
	BIN_OP_INDEX // Evaluates a slice-index
	BIN_OP_CONCAT
	BIN_OP_TYPECHECK
)

const (
	UNARY_OP_NOT = iota // Evaluates a 'not' of the top element, pops it, pushes result
)

// Special members
const (
	SMEMBER_location = iota
	SMEMBER_type
	SMEMBER_name
	SMEMBER_receiver
)