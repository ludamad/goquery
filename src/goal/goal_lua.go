package goal

import (
	"fmt"
	"github.com/aarzilli/golua/lua"
	"github.com/stevedonovan/luar"
	"io/ioutil"
	"runtime/debug"
	"strings"
)

// Exposes the (very) low level GoAL API.

func colorify(str interface{}, code string) interface{} {
	if !_USE_COLOR {
		return str
	}
	s := string([]byte{27})
	return fmt.Sprintf("%s[%sm%s%s[0m", s, code, str, s)
}

func colorPrintf(code string, fmtStr string, args ...interface{}) {
	if _USE_COLOR {
		fmt.Print(colorify(fmt.Sprintf(fmtStr, args...), code))
	} else {
		fmt.Printf(fmtStr, args...)
	}
}

func colorPrint(code string, args ...interface{}) {
	if _USE_COLOR {
		for _, arg := range args {
			fmt.Print(colorify(arg, code))
		}
	} else {
		fmt.Print(args)
	}
}

func findGoFiles(dir string) []string {
	io, err := ioutil.ReadDir(dir)
	if err != nil {
		fmt.Print(err)
		return nil
	}

	fnames := []string{}
	for _, file := range io {
		fname := file.Name()
		if strings.Index(fname, ".go") == len(fname)-3 {
			fnames = append(fnames, dir+"/"+fname)
		}
	}
	return fnames
}

var _API luar.Map = luar.Map{
	// See walker.go for details:
	"NewBytecodeContext": NewBytecodeContext,
	"NewGlobalContext":   NewGlobalContext,
	"FindGoFiles":        findGoFiles,
	"NullFileContext":    &FileSymbolContext{nil, nil},
	// See codes.go for details:
	"BC_CONSTANT":     BC_CONSTANT,
	"BC_PUSH":         BC_PUSH,
	"BC_PUSH_NIL":     BC_PUSH_NIL,
	"BC_NEXT":         BC_NEXT,
	"BC_MEMBER_PUSH":  BC_MEMBER_PUSH,
	"BC_SPECIAL_PUSH": BC_SPECIAL_PUSH,
	"BC_POPN":         BC_POPN,
	"BC_CONCATN":      BC_CONCATN,
	"BC_SAVE_TUPLE":   BC_SAVE_TUPLE,
	"BC_LOAD_TUPLE":   BC_LOAD_TUPLE,
	"BC_MAKE_TUPLE":   BC_MAKE_TUPLE,
	"BC_JMP_FALSE":    BC_JMP_FALSE,
	"BC_BIN_OP":       BC_BIN_OP,
	"BC_UNARY_OP":       BC_UNARY_OP,
	"BC_JMP":          BC_JMP,
	"BC_PRINTFN":      BC_PRINTFN,
	"BC_SPRINTFN":     BC_SPRINTFN,
	"Bytecode":        func(b1, b2, b3, b4 byte) Bytecode { return Bytecode{b1, b2, b3, b4} },

	"TypeInfo": _TYPE_INFO,

	"SMEMBER_receiver": SMEMBER_receiver,
	"SMEMBER_name":     SMEMBER_name,
	"SMEMBER_location": SMEMBER_location,
	"SMEMBER_type":     SMEMBER_type,

	"BIN_OP_AND":       BIN_OP_AND,
	"BIN_OP_OR":        BIN_OP_OR,
	"BIN_OP_XOR":       BIN_OP_XOR,
	"BIN_OP_INDEX":     BIN_OP_INDEX,
	"BIN_OP_CONCAT":     BIN_OP_CONCAT,
	"BIN_OP_TYPECHECK": BIN_OP_TYPECHECK,
	"BIN_OP_EQUAL": BIN_OP_EQUAL,

	"UNARY_OP_NOT": UNARY_OP_NOT,
	"UNARY_OP_LEN": UNARY_OP_LEN,
}

func NewGoalLuaContext(namespace string) *lua.State {
	L := luar.Init()
	luar.Register(L, namespace, _API)
	luar.Register(L, "", luar.Map{"ColorPrint": colorPrint})
	//	LuaDoString(L, _PRELUDE_SOURCE)
	ok := LuaDoFile(L, "src/goal/prelude.lua")
	if !ok {
		panic("Prelude is damaged.")
	}
	ok = LuaDoFile(L, "src/goal/macros.lua")
	if !ok {
		panic("Macro library is damaged.")
	}
	return L
}

func errorReportingCall(L *lua.State) bool {
	success := true
	defer func() {
		if r := recover(); r != nil {
			fmt.Print(colorify("An error has occurred!\n", "31;1"))
			fmt.Print(colorify(r, "31"))
			errS := r.(*lua.LuaError).Error()
			if strings.Contains(errS, "runtime error") || strings.Contains(errS, "interface conversion") ||
				strings.Contains(errS, "over slices!") || strings.Contains(errS, "error reflect:") {
				fmt.Printf("\nFull Go Stack:\n%s", colorify(debug.Stack(), "35;1"))
			}
			traceback, _ := luar.NewLuaObjectFromName(L, "debug.traceback").Call("")
			errStr := L.ToString(-1)
			fmt.Print(colorify(errStr, "31;1"))
			fmt.Print(colorify(traceback, "33;1"), "\n")
			success = false
		}
	}()
	L.MustCall(0, 0)
	return success
}

const _USE_COLOR = true

func LuaDoFile(L *lua.State, str string) bool {
	loadErr := L.LoadFile(str)
	if loadErr != 0 {
		fmt.Printf("Failed to load '%s'\n%s\n", str, L.ToString(-1))
		return false
	} else {
		return errorReportingCall(L)
	}
}

func LuaDoString(L *lua.State, str string) bool {
	loadErr := L.LoadString(str)
	if loadErr != 0 {
		fmt.Printf("Failed to load '%s'\n%s\n", str, L.ToString(-1))
		return false
	} else {
		return errorReportingCall(L)
	}
}
