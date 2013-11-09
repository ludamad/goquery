package goal

import (
	"go/ast"
	"reflect"
)

type EventContext struct {
	Events map[reflect.Type][]*BytecodeContext
}

func NewEventContext() *EventContext {
	return &EventContext{map[reflect.Type][]*BytecodeContext{}}
}

func (ev *EventContext) PushEvent(typ reflect.Type, bc *BytecodeContext) {
	if ev.Events[typ] == nil {
		ev.Events[typ] = []*BytecodeContext{}
	}
	ev.Events[typ] = append(ev.Events[typ], bc)
}

type traverseContext struct {
	*EventContext
	globSym *GlobalSymbolContext
	file    *FileSymbolContext
	stack *goalStack
}

func (ev *traverseContext) Visit(n ast.Node) ast.Visitor {
	if reflect.TypeOf(n) == nil {
		return ev
	}
	bcList := ev.Events[reflect.TypeOf(n).Elem()]
	if bcList != nil {
		for _, bc := range(bcList) {
			(*ev.stack)[0] = makeGoalRef(n)
			bc.Exec(ev.globSym, ev.file, ev.stack)
			if len(*ev.stack) > 1 {
				ev.stack.PopN(len(*ev.stack) - 1)
			}
		}
	}
	return ev
}

func (ev *EventContext) Analyze(globSym *GlobalSymbolContext, fileSym *FileSymbolContext) {
	tcontext := traverseContext{ev, globSym, fileSym, &goalStack{makeStrRef(nil)}}
	ast.Walk(&tcontext, fileSym.File)
}
