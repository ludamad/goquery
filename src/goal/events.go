package goal

import (
	"go/ast"
	"reflect"
)

type EventContext struct {
	Events map[reflect.Type]*BytecodeContext
}

func NewEventContext() *EventContext {
	return &EventContext{map[reflect.Type]*BytecodeContext{}}
}

type traverseContext struct {
	*EventContext
	globSym *GlobalSymbolContext
	file    *FileSymbolContext
}

func (ev *traverseContext) Visit(n ast.Node) ast.Visitor {
	if reflect.TypeOf(n) == nil {
		return ev
	}
	bc := ev.Events[reflect.TypeOf(n).Elem()]
	if bc != nil {
		bc.Exec(ev.globSym, ev.file, []interface{}{n})
	}
	return ev
}

func (ev *EventContext) Analyze(globSym *GlobalSymbolContext, fileSym *FileSymbolContext) {
	tcontext := traverseContext{ev, globSym, fileSym}
	ast.Walk(&tcontext, fileSym.File)
}
