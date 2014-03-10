package goal

import (
	"fmt"
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

type nodeRoot struct {
	node ast.Node
}

type nodeParentChain struct {
	node   ast.Node
	parent *nodeParentChain
	depth  int
}

type traverseContext struct {
	*EventContext
	chain   nodeParentChain
	globSym *GlobalSymbolContext
	file    *FileSymbolContext
	stack   *goalStack
}

func (ev *traverseContext) Visit(n ast.Node) ast.Visitor {
	if reflect.TypeOf(n) == nil {
		return ev
	}
	evChild := *ev
	evChild.chain = nodeParentChain{n, &ev.chain, ev.chain.depth + 1}
	bcList := ev.Events[reflect.TypeOf(n).Elem()]
	if bcList != nil {
		for _, bc := range bcList {
			(*ev.stack)[0] = makeGoalRef(n)
			bc.Exec(ev.globSym, ev.file, ev.stack, ev.chain)
			if len(*ev.stack) > 1 {
				ev.stack.PopN(len(*ev.stack) - 1)
			}
		}
	} else {
		fmt.Printf("%v: %v had no event!\n", reflect.TypeOf(n), n)
	}
	return &evChild
}

func (ev *EventContext) Analyze(globSym *GlobalSymbolContext, fileSym *FileSymbolContext) {

	chain := nodeParentChain{nil, nil, 0}
	tcontext := traverseContext{ev, chain, globSym, fileSym, &goalStack{makeStrRef(nil)}}
	ast.Walk(&tcontext, fileSym.File)
}
