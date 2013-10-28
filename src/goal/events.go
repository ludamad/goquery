package goal

import (
	"go/ast"
)

type TypeSpecEvents struct {
	InterfaceType *BytecodeContext
}

type EventContext struct {
	FuncDecl  *BytecodeContext
	TypeSpecEvents TypeSpecEvents
}

func NewEventContext() *EventContext {
	return new(EventContext)
}

type traverseContext struct {
	*EventContext
	globSym *GlobalSymbolContext
	file *FileSymbolContext
}

func (ev *traverseContext) event(bc *BytecodeContext, objs ...interface{}) {
	if bc != nil {
		bc.Exec(ev.globSym, ev.file, objs)
	}
}


func (ev *traverseContext) Visit(n ast.Node) ast.Visitor {
	switch node := n.(type) {
	case *ast.FuncDecl:
		ev.event(ev.FuncDecl, node)
	case *ast.TypeSpec:
		ev.handleTypeSpecNode(node)
	}
	return ev
}

func (ev *traverseContext) handleTypeSpecNode(t *ast.TypeSpec) {
	typeSpec := &ev.TypeSpecEvents
	switch t.Type.(type) {
	case *ast.InterfaceType:
		ev.event(typeSpec.InterfaceType, t, t.Type)
	}
}

func (ev *EventContext) Analyze(globSym *GlobalSymbolContext, fileSym *FileSymbolContext) {
	tcontext := traverseContext {ev, globSym, fileSym}
	ast.Walk(&tcontext, fileSym.File)
}