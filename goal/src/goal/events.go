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

type nodeParentChain struct {
	node ast.Node
	parent *nodeParentChain
	childNum int
}

type traverseContext struct {
	*EventContext
	chain nodeParentChain
	globSym *GlobalSymbolContext
	file    *FileSymbolContext
	stack *goalStack
}

func (ev *traverseContext) Visit(n ast.Node) ast.Visitor {
	if reflect.TypeOf(n) == nil {
		return ev
	}
	evChild := *ev
	evChild.chain = nodeParentChain {n, &ev.chain, 0}
	bcList := ev.Events[reflect.TypeOf(n).Elem()]
	if bcList != nil {
		for _, bc := range(bcList) {
			(*ev.stack)[0] = makeGoalRef(n)
			bc.Exec(ev.globSym, ev.file, ev.stack, ev.chain)
			if len(*ev.stack) > 1 {
				ev.stack.PopN(len(*ev.stack) - 1)
			}
		}
	}
	// Keep track of the child order:
	ev.chain.childNum += 1
	return &evChild
}

func (ev *EventContext) Analyze(globSym *GlobalSymbolContext, fileSym *FileSymbolContext) {
	tcontext := traverseContext{ev, nodeParentChain{nil,nil, 0}, globSym, fileSym, &goalStack{makeStrRef(nil)}}
	ast.Walk(&tcontext, fileSym.File)
}
