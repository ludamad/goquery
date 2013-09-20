// adomurad:
//  Reference material:
//   http://golang.org/src/pkg/go/ast/example_test.go
//   https://github.com/mattn/go-sqlite3/blob/master/_example/simple/simple.go

package main

import (
	"database/sql"
	"fmt"
	_ "github.com/mattn/go-sqlite3"
	"go/ast"
	"go/parser"
	"go/token"
	"log"
	"os"
)

type Method struct {
	Package, Name string
}

func InsertMethods(db *sql.DB, methods []Method) {
	tx, err := db.Begin()
	if err != nil {
		log.Fatal(err)
	}
	stmt, err := tx.Prepare("INSERT INTO methods(package, name) values(?, ?)")
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()

	for _, method := range methods {
		fmt.Printf("Method '%s.%s' added to DB\n", method.Package, method.Name)
		_, err = stmt.Exec(method.Package, method.Name)
		if err != nil {
			log.Fatal(err)
		}
	}
	tx.Commit()
}

func DumpAstToDB(db *sql.DB, file_ast *ast.File) {
	methods := []Method{}
	// Inspect the AST and print all identifiers and literals.
	ast.Inspect(file_ast, func(n ast.Node) bool {
		if f, ok := n.(*ast.FuncDecl); ok {
			fmt.Printf("Method '%s.%s' found\n", file_ast.Name, f.Name)
			methods = append(methods, Method{file_ast.Name.Name, f.Name.Name})
		}
		return true
	})
	InsertMethods(db, methods)
}

func main() {
	log.Printf("%d", os.Args)
	if len(os.Args) < 1 {
		log.Fatal("Expected usage: goquery <source file>")
	}

	os.Remove("hello-world.db")
	db, err := sql.Open("sqlite3", "./hello-world.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	sql := "CREATE TABLE methods(package TEXT, name TEXT, PRIMARY KEY (package, name))"
	_, err = db.Exec(sql)
	if err != nil {
		log.Printf("%q: %s\n", err, sql)
		return
	}
	fset := token.NewFileSet()
	file_ast, err := parser.ParseFile(fset, os.Args[1], nil, 0)
	if err != nil {
		log.Fatal(err)
	}
	DumpAstToDB(db, file_ast)
}
