package main

import (
    "fmt"
    "os"
    "go/token"
    "go/ast"
    "go/parser"
    "flag"
    "reflect"
    "strings"
)

const INDENT = "| "

type walker struct {
    depth int
    skipSubtree bool
}

func (w *walker) Visit(node ast.Node) ast.Visitor {
    var (
        w2 ast.Visitor = w
    )

    if node != nil {
        w.depth += 1
        fmt.Print(strings.Repeat(INDENT, w.depth))

        v := reflect.ValueOf(node)
        if(v.Kind() == reflect.Ptr) {
            v = v.Elem()
        }
        fmt.Printf("[%s]", v.Type().String())
        defer fmt.Println()

        switch node := node.(type) {
        case *ast.ImportSpec:
            fmt.Printf(" path(%s)", node.Path.Value)
            w.depth -= 1
            w2 = nil
        }
    } else {
        w.depth -= 1
    }
    return w2
}

func main() {
    var (
        filename string
        parsetree *ast.File
        fileset *token.FileSet
        err error
        f *walker
    )

    flag.StringVar(&filename, "f", "", "specify go file to parse")
    flag.Parse()

    if filename == "" {
        fmt.Println("Usage: -f <go file>")
        os.Exit(1)
    }

    fileset = token.NewFileSet()
    f = &walker{}

    parsetree, err = parser.ParseFile(fileset, filename, nil, 0)

    if err != nil {
        fmt.Println(err)
        os.Exit(0)
    }

    ast.Walk(f, parsetree)
}
