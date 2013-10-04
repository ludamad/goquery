package goquery

import (
	"database/sql"
	"fmt"
	"go/token"
	"log"
	"os"
	"strings"
)

func posString(pos token.Position) string {
	return fmt.Sprintf("%s:%d:%d", pos.Filename, pos.Line, pos.Column)
}

func (iface InterfaceDeclaration) DBAdd(db *sql.DB) {
	for _, req := range iface.Requirements {
		dbInsert(db, "interface_reqs(interface, name, type, location)", iface.Name, req.Name, req.TypeRepr, posString(req.Pos))
	}
}

func (method MethodDeclaration) DBAdd(db *sql.DB) {
	dbInsert(db, "methods(name, type, receiver_type, location)", method.Name, method.SignatureTypeRepr, method.ReceiverTypeRepr, posString(method.Pos))
}

func (function FuncDeclaration) DBAdd(db *sql.DB) {
	dbInsert(db, "functions(name, type, location)", function.Name, function.SignatureTypeRepr, posString(function.Pos))
}

func (typ TypeDeclaration) DBAdd(db *sql.DB) {
	dbInsert(db, "types(name, type, location)", typ.Name, typ.TypeRepr, posString(typ.Pos))
}

func (ref Ref) DBAdd(db *sql.DB) {
	dbInsert(db, "refs(name, location)", ref.Name, posString(ref.Pos))
}

func DBInitialize(driver string, filename string, deletePrevious bool) *sql.DB {
	if deletePrevious {
		os.Remove(filename)
	}
	db, err := sql.Open(driver, filename)
	if err != nil {
		log.Fatal(err)
	}
	dbExec(db, "CREATE TABLE methods(name TEXT, type TEXT, receiver_type TEXT, location TEXT, PRIMARY KEY (name, type, receiver_type))")
	dbExec(db, "CREATE TABLE functions(name TEXT, type TEXT, location TEXT, PRIMARY KEY (name, type))")
	dbExec(db, "CREATE TABLE interface_reqs(interface TEXT, name TEXT, type TEXT, location TEXT, PRIMARY KEY (interface, name, type))")
	dbExec(db, "CREATE TABLE types(name TEXT, type TEXT, location TEXT, PRIMARY KEY (name))")
	dbExec(db, "CREATE TABLE refs(name TEXT, location TEXT, PRIMARY KEY (location))")
	return db
}

func dbExec(db *sql.DB, sql string) {
	_, err := db.Exec(sql)
	if err != nil {
		log.Printf("Problem in sql exec\n\t%s\n", sql)
		log.Fatal(err)
	}
}

func dbInsert(db *sql.DB, schema string, args ...interface{}) {
	// Assumes at least one arg in 'args':
	marks := "?" + strings.Repeat(", ?", len(args) - 1)
	sql := "INSERT INTO " + schema + " values(" + marks + ")"
	dbAction(db, sql, args...)
}

func fail(sql string, err error, args ...interface{}) {
	fmt.Printf("Problem in action begin:\n\t%s\n", sql)
	fmt.Printf("Got args:\n\t")
	fmt.Println(args...)
	log.Fatal(err)
}

func dbAction(db *sql.DB, sql string, args ...interface{}) {
	tx, err := db.Begin()
	if err != nil {
		fail(sql, err, args)
	}

	stmt, err := tx.Prepare(sql)
	if err != nil {
		fail(sql, err, args)
	}
	defer stmt.Close()
	_, err = stmt.Exec(args...)
	if err != nil {
		fail(sql, err, args)
	}

	tx.Commit()
}
