package goal

import (
	"code.google.com/p/go.tools/go/types"
	"fmt"
	"os"
	"go/ast"
	"go/parser"
	"go/token"
	"time"
)

type GlobalSymbolContext struct {
	*DataContext
	FileSet       *token.FileSet
	Events        *EventContext
	Info          *types.Info
	NameToAstFile map[string]*ast.File
}

func NewGlobalContext() *GlobalSymbolContext {
	info := &types.Info{}
	info.Types = make(map[ast.Expr]types.TypeAndValue)
	info.Implicits = make(map[ast.Node]types.Object)
	info.Objects = make(map[*ast.Ident]types.Object)
	info.Scopes = make(map[ast.Node]*types.Scope)
	info.InitOrder = []*types.Initializer{}
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

func isDirectory(path string) (bool) {
	f, err := os.Stat(path)
	if err == nil {
		return f.Mode().IsDir()		
	}	
	return false
}

func (context *GlobalSymbolContext) ParseAndInferTypes(filename string) {
	if isDirectory(filename) {
		// File set aggregates all token information for all our files
		pkgs, err := parser.ParseDir(context.FileSet, filename, func(os.FileInfo) bool {return true}, parser.AllErrors)
		if err != nil {
			fmt.Println("Problem in ParseAndInferTypes:\n", err)
			return;
		}
		for pkgName, pkg := range pkgs {
			files := []*ast.File{}
			fmt.Println(pkgName, pkg)
			for filename, file := range pkg.Files {
				context.NameToAstFile[filename] = file
				files = append(files, file)
			}
			context.inferTypes(pkg.Name, files)
		}
	} else {
		file, err := parser.ParseFile(context.FileSet, filename, nil, parser.AllErrors)
		if err != nil {
			fmt.Println("Problem in ParseAndInferTypes:\n", err)
			return;
		}
		context.NameToAstFile[filename] = file
		context.inferTypes(file.Name.Name, []*ast.File{file})
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
	nodeCount int
}

// Returns a unique (within the current session!) ID for the object:
func (context *FileSymbolContext) GetObjectId(node ast.Node) int {
	N := &context.idContext.nodeToObjectID
	val, ok := (*N)[node]
	if !ok {
		(*N)[node] = val
	}
	return val
}

type FileSymbolContext struct {
	File      *ast.File
	TokenFile *token.File
	idContext nodeIDContext
}

func NewFileSymbolContext(file *ast.File, tokenFile *token.File) *FileSymbolContext {
	idContext := nodeIDContext {map[ast.Node]int{}, 0}
	return &FileSymbolContext {file, tokenFile, idContext}
}

func (fileSym *FileSymbolContext) PositionString(node ast.Node) string {
	pos := fileSym.TokenFile.Position(node.Pos())
	return fmt.Sprintf("%s:%d:%d", pos.Filename, pos.Line, pos.Column)
}
