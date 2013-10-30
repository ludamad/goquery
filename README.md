Goquery
=======
Undergraduate computer science project at UOIT, year 2013-2014.  
Goquery intends to be a tool or set of small tools, time permitting.

Currently in progress is a DSL for traversing Go languages.

The DSL is implemented using the luar package and builds a small set of bytecode operations:

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
	BC_JMP_STR_ISEMPTY // Takes <code index>, jumps if the top string index is nil. Pops the top element
	BC_JMP_OBJ_ISNIL // Takes <code index>, jumps if the top object index is nil. Pops the top element
	BC_JMP // Takes <code index>, jumps unconditionally
	BC_PRINTFN // Takes <N>, first string is treated as format specifier, pops N

Exposes this low level API to Lua using Luar:

	// See walker.go for details:
	"NewBytecodeContext": NewBytecodeContext,
	"NewGlobalContext":   NewGlobalContext,
	"FindGoFiles":        findGoFiles,
	"NullFileContext":    &FileSymbolContext{nil, nil},
	// See codes.go for details:
	"BC_STRING_PUSH":     BC_STRING_PUSH,
	"BC_STRING_CONSTANT": BC_STRING_CONSTANT,
	"BC_OBJECT_PUSH":     BC_OBJECT_PUSH,
	"BC_LOOP_PUSH":       BC_LOOP_PUSH,
	"BC_POP_STRINGSN":    BC_POP_STRINGSN,
	"BC_POP_OBJECTSN":    BC_POP_OBJECTSN,
	"BC_LOAD_TUPLE":      BC_LOAD_TUPLE,
	"BC_SAVE_TUPLE":      BC_SAVE_TUPLE,
	"BC_MAKE_TUPLE":      BC_MAKE_TUPLE,
	"BC_CONCATN":         BC_CONCATN,
	"BC_JMP_STR_ISEMPTY": BC_JMP_STR_ISEMPTY,
	"BC_JMP_OBJ_ISNIL":   BC_JMP_OBJ_ISNIL,
	"BC_JMP":             BC_JMP,
	"BC_PRINTFN":         BC_PRINTFN,
	"Bytecode":           func(b1, b2, b3, b4 byte) Bytecode { return Bytecode{b1, b2, b3, b4} },
	"OMEMBER_Signature": OMEMBER_Signature,
	"OMEMBER_Receiver":  OMEMBER_Receiver,
	"LMEMBER_Methods": LMEMBER_Methods,
	"SMEMBER_name":     SMEMBER_name,
	"SMEMBER_location": SMEMBER_location,
	"SMEMBER_type":     SMEMBER_type,

The DSL compiler is completely implemented in Lua using these very low level direct wrappings. The Go runtime has no concept of correct code. [The Lua compiler is in one (long) file here](https://github.com/ludamad/goquery/blob/master/src/goal/prelude.lua).
