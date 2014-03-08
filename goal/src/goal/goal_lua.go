package goal

import (
	"fmt"
	"github.com/aarzilli/golua/lua"
	"github.com/shavac/readline"
	"github.com/stevedonovan/luar"
	"io/ioutil"
	"runtime/debug"
	"strings"
	"time"
)

// Exposes the (very) low level GoAL API.

func colorify(str interface{}, code string) interface{} {
	if !_USE_COLOR {
		return str
	}
	return fmt.Sprintf("\x1b[%sm%s\x1b[0m", code, str)
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

// If extension is "", finds directories
func findFilesAux(extension string, dir string, fnames []string) []string {
	io, err := ioutil.ReadDir(dir)
	if err != nil {
		panic(err)
	}
	for _, file := range io {
		fname := file.Name()
		fullName := dir + "/" + fname
		shouldMatchDir := (extension == "")
		isMatch := false
		if shouldMatchDir && file.IsDir() {
			isMatch = true
		} else if !shouldMatchDir && len(fname) > len(extension) {
			fmt.Print(fname)
			expectedLoc := len(fname)- len(extension)
			isMatch = (strings.Index(fname, extension) == expectedLoc)
			fmt.Print(isMatch)
		}
		if isMatch {
			fnames = append(fnames, fullName)
		}
		if file.IsDir() {
			// Search recursively:
			fnames = findFilesAux(extension, fullName, fnames)
		}
	}
	return fnames
}

func findGoFiles(dir string) []string {
	fnames := []string{}
	fnames = findFilesAux(".go", dir, fnames)
	return fnames
}

func findYAMLFiles(dir string) []string {
	fnames := []string{}
	fnames = findFilesAux(".yaml", dir, fnames)
	return fnames
}

func findSubdirectories(dir string) []string {
	fnames := []string{}
	fnames = findFilesAux("", dir, fnames)
	return fnames
}

func bytesToString(byteArray []byte) string {
	return string(byteArray[:])
}

// Slight wrapper to handle pointer boxing/unboxing
func readLineWrap(prompt string) interface{} {
	result := readline.ReadLine(&prompt)
	if result == nil {
		return nil
	} else {
		return *result
	}
}

var _API luar.Map = luar.Map{
	// See walker.go for details:
	"NewBytecodeContext": NewBytecodeContext,
	"NewGlobalContext":   NewGlobalContext,
	"FindGoFiles":        findGoFiles,
	"FindYAMLFiles":      findYAMLFiles,
	"FindSubdirectories": findSubdirectories,
	"NullFileContext":    &FileSymbolContext{nil, nil},
	// See codes.go for details:
	"CurrentTime":     time.Now,
	"BC_CONSTANT":     BC_CONSTANT,
	"BC_PUSH":         BC_PUSH,
	"BC_PUSH_NIL":     BC_PUSH_NIL,
	"BC_NEXT":         BC_NEXT,
	"BC_MEMBER_PUSH":  BC_MEMBER_PUSH,
	"BC_SPECIAL_PUSH": BC_SPECIAL_PUSH,
	"BC_POPN":         BC_POPN,
	"BC_CONCATN":      BC_CONCATN,
	"BC_SAVE_TUPLE":   BC_SAVE_TUPLE,
	"BC_JMP_FALSE":    BC_JMP_FALSE,
	"BC_BIN_OP":       BC_BIN_OP,
	"ColorPrint":      colorPrint,
	"BC_UNARY_OP":     BC_UNARY_OP,
	"BC_JMP":          BC_JMP,
	"BC_PRINTFN":      BC_PRINTFN,
	"BC_SPRINTFN":     BC_SPRINTFN,
	"BytesToString":   bytesToString,
	"NewObjectStack": func(objs ...interface{}) *goalStack {
		gs := &goalStack{}
		for _, obj := range objs {
			gs.Push(makeGoalRef(obj))
		}
		return gs
	},
	"MakeGoalRef":        makeGoalRef,
	"ReadLine":           readLineWrap,
	"ReadLineAddHistory": readline.AddHistory,
	"Bytecode":           func(b1, b2, b3, b4 byte) Bytecode { return Bytecode{b1, b2, b3, b4} },

	"TypeInfo": _TYPE_INFO,

	"SMEMBER_receiver": SMEMBER_receiver,
	"SMEMBER_name":     SMEMBER_name,
	"SMEMBER_location": SMEMBER_location,
	"SMEMBER_type":     SMEMBER_type,

	"BIN_OP_AND":       BIN_OP_AND,
	"BIN_OP_OR":        BIN_OP_OR,
	"BIN_OP_XOR":       BIN_OP_XOR,
	"BIN_OP_INDEX":     BIN_OP_INDEX,
	"BIN_OP_CONCAT":    BIN_OP_CONCAT,
	"BIN_OP_TYPECHECK": BIN_OP_TYPECHECK,
	"BIN_OP_EQUAL":     BIN_OP_EQUAL,

	"UNARY_OP_NOT": UNARY_OP_NOT,
	"UNARY_OP_LEN": UNARY_OP_LEN,
}

func NewGoalLuaContext(namespace string) *lua.State {
	L := luar.Init()
	luar.Register(L, namespace, _API)
	luar.Register(L, "", luar.Map {
		"ColorPrint": colorPrint,
		"Colorify": colorify,
	})
	return L
}

func errorReportingCall(L *lua.State) bool {
	success := true
	defer func() {
		if r := recover(); r != nil {
			fmt.Print(colorify("An error has occurred!\n", "31;1"))
			fmt.Print(colorify(r, "31"))
			errS := r.(*lua.LuaError).Error()
			if strings.Contains(errS, "error") || strings.Contains(errS, "interface conversion") ||
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
