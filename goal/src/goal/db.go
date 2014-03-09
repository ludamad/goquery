package goal

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
	"os"
	"regexp"
	"strings"
)

type DatabaseContext struct {
	DB                *sql.DB
	insertTransaction *sql.Tx
	insertStatements  map[int]*sql.Stmt
}

func (context *DatabaseContext) makeInsertStatement(name string, fields []field) *sql.Stmt {
	if context.insertTransaction == nil { // Make sure we have an action transaction
		tx, err := context.DB.Begin()
		if err != nil {
			panic(err)
		}
		context.insertTransaction = tx
	}
	// Assumes at least one arg in 'args':
	marks := "?" + strings.Repeat(", ?", len(fields)-1)
	sql := "INSERT INTO " + name + " values(" + marks + ")"
	stmt, err := context.insertTransaction.Prepare(sql)
	if err != nil {
		panic(err)
	}
	return stmt
}

func (context *DatabaseContext) GetInsertStatement(ds *DataSchema) *sql.Stmt {
	stmt := context.insertStatements[ds.Id]
	if stmt == nil {
		stmt = context.makeInsertStatement(ds.Name, ds.Fields)
		context.insertStatements[ds.Id] = stmt
	}
	return stmt
}

// Database connection and insertion functions:
func newDBConnection(dbKind string, filename string, deletePrevious bool) *sql.DB {
	if deletePrevious {
		os.Remove(filename)
	}
	db, err := sql.Open(dbKind, filename)
	if err != nil {
		panic(err)
	}
	return db
}

func (context *DatabaseContext) OpenConnection(dbKind string, filename string, deletePrevious bool) {
	if context.DB != nil {
		panic("Database connection already open!")
	}
	context.DB = newDBConnection(dbKind, filename, deletePrevious)
}
func (context *DatabaseContext) CloseConnection() {
	if context.DB != nil {
		context.Commit()
		context.DB.Close()
		context.DB = nil
	}
}

func (context *DatabaseContext) Commit() {
	for i, stmt := range context.insertStatements {
		stmt.Close()
		delete(context.insertStatements, i)
	}
	if context.insertTransaction != nil {
		context.insertTransaction.Commit()
		context.insertTransaction = nil
	}
}
func (context *DataContext) DropAllData() {
	context.Commit()
	for _, s := range context.Schemas {
		sqlCheckName(s.Name)
		_, err := context.DB.Exec("drop table " + s.Name)
		if err != nil {
			panic(err)
		}
		s.CreateTable(context.DatabaseContext)
	}
}

// Global symbol context functions:
// Run a query. Return the column names, and the tuple results.
func (context *DatabaseContext) Query(query string, args ...interface{}) ([]string, [][]interface{}) {
	rows, err := context.DB.Query(query, args...)
	if err != nil {
		panic(err)
	}
	columns, _ := rows.Columns()
	results := [][]interface{}{}
	for rows.Next() {
		ifaceBoxes := []interface{}{}
		for i := 0; i < len(columns); i++ {
			ifaceBoxes = append(ifaceBoxes, new(interface{}))
		}
		err = rows.Scan(ifaceBoxes...)
		result := make([]interface{}, len(columns))
		for i := 0; i < len(columns); i++ {
			result[i] = *ifaceBoxes[i].(*interface{})
		}
		results = append(results, result)
	}
	err = rows.Err()
	if err != nil {
		panic(err)
	}
	return columns, results
}

func sqlCheckName(name string) {
	if match, _ := regexp.MatchString(name, "^[\\w_]+$"); match {
		panic("Sql-exposed names must consist only of alphanumeric characters, or _! Bad name: " + name)
	}
}

func (ds *DataSchema) CreateTable(context *DatabaseContext) {
	sqlCheckName(ds.Name) // Be a little safer about string interpolation
	fieldSchema := []string{}
	for _, f := range ds.Fields {
		sqlCheckName(f.Name)
		fieldSchema = append(fieldSchema, f.Name+" "+ f.Type)
	}
	sql := fmt.Sprintf("CREATE TABLE %s(%s, PRIMARY KEY (%s))", ds.Name, strings.Join(fieldSchema, ","), strings.Join(ds.Keys, ","))
	_, err := context.DB.Exec(sql)
	if err != nil {
		panic(err)
	}
}

func (ds *DataSchema) Insert(context *DatabaseContext, fieldData []interface{}) {
	context.GetInsertStatement(ds).Exec(fieldData...)
}
