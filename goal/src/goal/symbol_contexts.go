package goal

import (
	"code.google.com/p/go.tools/go/types"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"time"
)

type GlobalSymbolContext struct {
	*DataContext
	FileSet       *token.FileSet
	Events        *EventContext
	Info          *types.Info
	NameToAstFile map[string]*ast.File
	idContext     nodeIDContext
}

func NewGlobalContext() *GlobalSymbolContext {
	info := &types.Info{}
	info.Types = make(map[ast.Expr]types.TypeAndValue)
	info.Implicits = make(map[ast.Node]types.Object)
	info.Objects = make(map[*ast.Ident]types.Object)
	info.Scopes = make(map[ast.Node]*types.Scope)
	info.InitOrder = []*types.Initializer{}
	idContext := nodeIDContext{map[ast.Node]int{}, 0}
	return &GlobalSymbolContext{MakeDataContext(), token.NewFileSet(), NewEventContext(), info, map[string]*ast.File{}, idContext}
}

func (context *GlobalSymbolContext) FileList() []*ast.File {
	list := []*ast.File{}
	for _, file := range context.NameToAstFile {
		list = append(list, file)
	}
	return list
}

func (context *GlobalSymbolContext) ParseAndInferTypesAll(files []string) {

	defer timeTrack(time.Now(), "ParseAndInferTypesAll")
	for _, filename := range files {
		context.ParseAndInferTypes(filename)
	}
}

func (context *GlobalSymbolContext) ClearParseResults() {
	context.DropAllData()
	context.FileSet = token.NewFileSet()
	context.NameToAstFile = map[string]*ast.File{}
}

func timeTrack(start time.Time, name string) {
	elapsed := time.Since(start)
	fmt.Printf("%s took %fms\n", name, elapsed.Seconds()*1000.0)

}

func (context *GlobalSymbolContext) AnalyzeAll(files []string) {

	context.ClearParseResults()
	context.ParseAndInferTypesAll(files)

	defer timeTrack(time.Now(), "AST Traversal")
	for _, fileSym := range context.FileContextMap() {
		context.Events.Analyze(context, fileSym)
	}
	context.Commit()
}

func isDirectory(path string) bool {
	f, err := os.Stat(path)
	if err == nil {
		return f.Mode().IsDir()
	}
	return false
}

func (context *GlobalSymbolContext) ParseAndInferTypes(filename string) {
	if isDirectory(filename) {
		// File set aggregates all token information for all our files
		pkgs, err := parser.ParseDir(context.FileSet, filename, func(os.FileInfo) bool { return true }, parser.DeclarationErrors)
		if err != nil {
			//fmt.Println("Problem in ParseAndInferTypes:\n", err)
			return
		}
		for _, pkg := range pkgs {
			files := []*ast.File{}
			for filename, file := range pkg.Files {
				context.NameToAstFile[filename] = file
				files = append(files, file)
			}
			context.inferTypes(filename, pkg.Name, files)
		}
	} else {
		file, err := parser.ParseFile(context.FileSet, filename, nil, parser.DeclarationErrors)
		if err != nil {
			//fmt.Println("Problem in ParseAndInferTypes:\n", err)
			return
		}
		context.NameToAstFile[filename] = file
		context.inferTypes(filepath.Dir(filename), file.Name.Name, []*ast.File{file})
	}
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
		fc := NewFileSymbolContext(file, tokenFiles[name])
		m[name] = fc
	}
	return m
}

type nodeIDContext struct {
	nodeToObjectID map[ast.Node]int
	nodeCount      int
}

// Returns a unique (within the current session!) ID for the object:
func (context *GlobalSymbolContext) GetObjectId(node ast.Node) int {
	N := &context.idContext.nodeToObjectID
	C := &context.idContext.nodeCount
	val, ok := (*N)[node]
	if !ok {
		(*C)++
		val = *C
		(*N)[node] = val
	}
	return val
}

type FileSymbolContext struct {
	File      *ast.File
	TokenFile *token.File
}

func NewFileSymbolContext(file *ast.File, tokenFile *token.File) *FileSymbolContext {
	return &FileSymbolContext{file, tokenFile}
}

func (fileSym *FileSymbolContext) PositionString(node ast.Node, end bool) string {
	var pos token.Position
	if end {
		pos = fileSym.TokenFile.Position(node.End())
	} else {
		pos = fileSym.TokenFile.Position(node.Pos())
	}
	return fmt.Sprintf("%s:%d:%d", pos.Filename, pos.Line, pos.Column)
}
