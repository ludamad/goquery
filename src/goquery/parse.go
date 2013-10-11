package goquery

import (
	"fmt"
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
	fmt.Printf("Parsing '%s'...\n", filename)
	if err != nil {
		fmt.Println("Problem in parseFile:")
		panic(err)
	}
	fmt.Printf("Done parsing '%s'...\n", filename)
	context.nameToAstFile[filename] = file
}
