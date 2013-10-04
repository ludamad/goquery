package goquery

import (
	"go/parser"
)

func (context *SymbolContext) Parse(files []string) {
	for _, filename := range files {
		context.parseFile(filename)
	}
	context.resolveTypes()
}

func (context *SymbolContext) parseFile(filename string) {
	file, err := parser.ParseFile(context.fileSet, filename, nil, parser.DeclarationErrors|parser.AllErrors)
	if err != nil {
		panic(err)
	}
	context.nameToAstFile[filename] = file
}