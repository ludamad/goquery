package goal

import (
	"fmt"
	"code.google.com/p/go.tools/go/types"
	"go/ast"
	"go/parser"
	"go/token"
	"time"
)

type GlobalSymbolContext struct {
	*DataContext
	FileSet       *token.FileSet
	Events        *EventContext
	Info	   	*types.Info
	NameToAstFile map[string]*ast.File
}

func NewGlobalContext() *GlobalSymbolContext {
	info := &types.Info{}
	info.Types = make(map[ast.Expr]types.TypeAndValue)
	return &GlobalSymbolContext{MakeDataContext(), token.NewFileSet(), NewEventContext(), info, map[string]*ast.File{}}
}

func (context *GlobalSymbolContext) FileList() []*ast.File {
	list := []*ast.File{}
	for _, file := range context.NameToAstFile {
		list = append(list, file)
	}
	return list
}

func (context *GlobalSymbolContext) ParseAndInferTypesAll(files []string) {
	for _, filename := range files {
		context.ParseAndInferTypes(filename, nil)
	}
}

func (context *GlobalSymbolContext) ClearParseResults() {
	context.DropAllData()
	context.FileSet = token.NewFileSet()
	context.NameToAstFile = map[string]*ast.File{}
}

func timeTrack(start time.Time, name string) {
	elapsed := time.Since(start)
	fmt.Printf("%s took %s\n", name, elapsed)
}

func (context *GlobalSymbolContext) AnalyzeAll(files []string) {

	context.ClearParseResults()
	context.ParseAndInferTypesAll(files)

	defer timeTrack(time.Now(), "Actual Analysis")
	for _, fileSym := range context.FileContextMap() {
		context.Events.Analyze(context, fileSym)
	}
}

func (context *GlobalSymbolContext) ParseAndInferTypes(filename string, altSource interface{}) {
	fileSet := &token.FileSet{}
	file, err := parser.ParseFile(fileSet, filename, altSource, parser.DeclarationErrors|parser.AllErrors)
	context.inferTypes(filename, fileSet, file)
	
	if err != nil {
		fmt.Println("Problem in ParseFile:\n", err)
	}
	context.NameToAstFile[filename] = file
}

func (context *GlobalSymbolContext) FileContextMap() map[string]*FileSymbolContext {
	// Collect token files in a map
	tokenFiles := map[string]*token.File{}
	context.FileSet.Iterate(func(file *token.File) bool {
		tokenFiles[file.Name()] = file
		return true
	})

	// Build the file contexts
	m := map[string]*FileSymbolContext{}
	for name, file := range context.NameToAstFile {
		fc := &FileSymbolContext{file, tokenFiles[name]}
		m[name] = fc
	}
	return m
}

type FileSymbolContext struct {
	File      *ast.File
	TokenFile *token.File
}

func (fileSym *FileSymbolContext) PositionString(node ast.Node) string {
	pos := fileSym.TokenFile.Position(node.Pos())
	return fmt.Sprintf("%s:%d:%d", pos.Filename, pos.Line, pos.Column)
}
