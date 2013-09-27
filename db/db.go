package db

import (
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
	"log"
	"os"
	"fmt"
)

// Helpers to reduce boilerplate:
func _DBExec(db *sql.DB, sql string) {
	_, err := db.Exec(sql)
	if err != nil {
		log.Fatal(err)
	}
}

func _DBAction(db *sql.DB, sql string, test... interface{}) {
	tx, err := db.Begin()
	if err != nil {
		log.Fatal(err)
	}

	stmt, err := tx.Prepare(sql)
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()
	_, err = stmt.Exec(test...)
	if err != nil {
		log.Fatal(err)
	}

	tx.Commit()
} 

type InterfaceRequirement struct {
	Name, TypeRepr string
	
}

type InterfaceDeclaration struct {
	Name string
	Requirements []InterfaceRequirement
}

func DBAddInterfaceDeclaration(db *sql.DB, iface InterfaceDeclaration) {
	for _, req := range iface.Requirements {
		fmt.Printf("Interface requirement for %s: '%s' type '%s' added to DB\n", iface.Name, req.Name, req.TypeRepr)
		_DBAction(db, "INSERT INTO interface_reqs(interface, name, type) values(?, ?, ?)", iface.Name, req.Name, req.TypeRepr)
	}
}

type MethodDeclaration struct {
	Name string
	SignatureTypeRepr string
	ReceiverTypeRepr string // Can be '' == no receiver
}

func DBAddMethodDeclaration(db *sql.DB, method MethodDeclaration) {
	fmt.Printf("Method '%s' type '%s' receiver '%s' added to DB\n", method.Name, method.SignatureTypeRepr, method.ReceiverTypeRepr)
	_DBAction(db, "INSERT INTO methods(name, type, receiver_type) values(?, ?, ?)", method.Name, method.SignatureTypeRepr, method.ReceiverTypeRepr)
}

type TypeDeclaration struct {
	Name string
	TypeRepr string
}

func DBAddTypeDeclaration(db *sql.DB, typeDecl TypeDeclaration) {
	fmt.Printf("Type '%s' = '%s' added to DB\n", typeDecl.Name, typeDecl.TypeRepr)
	_DBAction(db, "INSERT INTO types(name, type) values(?, ?)", typeDecl.Name, typeDecl.TypeRepr)
}

func DBInitialize() *sql.DB {
	os.Remove("./hello-world.db")
	db, err := sql.Open("sqlite3", "./hello-world.db")
	if err != nil {
		log.Fatal(err)
	}
	_DBExec(db, "CREATE TABLE methods(name TEXT, type TEXT, receiver_type TEXT, PRIMARY KEY (name, type, receiver_type))")
	_DBExec(db, "CREATE TABLE interface_reqs(interface TEXT, name TEXT, type TEXT, PRIMARY KEY (interface, name, type))")
	_DBExec(db, "CREATE TABLE types(name TEXT, type TEXT, PRIMARY KEY (name))")
	return db
}
