package goal

import (
	_ "github.com/mattn/go-sqlite3"
	"database/sql"
	"os"
	"strings"
	"fmt"
	"regexp"
)

type DatabaseContext struct {
	db *sql.DB
	insertCount int
	insertTransaction *sql.Tx
}

// Global symbol context functions:
// Run a query. Return the column names, and the tuple results.
func (context *GlobalSymbolContext) Query(query string, args ...interface{}) ([]string, [][]interface{}) {
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

// Database connection and insertion functions:
func NewDBConnection(filename string, deletePrevious bool) *sql.DB {
	if deletePrevious {
		os.Remove(filename)
	}
	db, err := sql.Open("sqlite3", filename)
	if err != nil {
		panic(err)
	}
	return db
}

func (b *insertBatcher) Insert(fieldData []interface{}) {
	b.insertStatement.Exec(fieldData...)
}

func (b *insertBatcher) Close() {
	b.insertStatement.Close()
	b.insertTransaction.Commit()
}

func makeInsertBatcher(db *sql.DB, name string, fields []field) *insertBatcher {
	// Assumes at least one arg in 'args':
	marks := "?" + strings.Repeat(", ?", len(fields)-1)
	sql := "INSERT INTO " + name + " values(" + marks + ")"
	tx, err := db.Begin()
	if err != nil {
		panic(err)
	}

	stmt, err := tx.Prepare(sql)
	if err != nil {
		panic(err)
	}
	return &insertBatcher{0, tx, stmt}
}

type DatabaseSchema struct {
	Name       string
	Fields     []field
	Keys []string
	insertStatement	*sql.Stmt
}

func makeDatabaseSchema(name string, fields []field, keys []string) *DatabaseSchema {
	return &DatabaseSchema {name, fields, keys, nil}
}

func (ds *DatabaseSchema) Flush() {
	if ds.batcher != nil {
		ds.batcher.Close() ; ds.batcher = nil
	}
}

func sqlCheckName(name string) {
	if match,_ := regexp.MatchString(name, "^[\\w_]+$") ; match {
		panic("Sql-exposed names must consist only of alphanumeric characters, or _! Bad name: " + name)
	}
}

func (ds *DatabaseSchema) CreateTable(db *sql.DB) {
	sqlCheckName(ds.Name) // Be a little safer about string interpolation
	fieldSchema := []string{}
	for _, f := range ds.Fields {
		sqlCheckName(f.Name)
		if f.Type == FIELD_TYPE_STRING {
			fieldSchema = append(fieldSchema, f.Name + " TEXT")
		} else {
			panic("Unexpected field type!")
		}
	}
	sql := fmt.Sprintf("CREATE TABLE %s(%s, PRIMARY KEY (%s))", ds.Name, strings.Join(fieldSchema, ","), strings.Join(ds.Keys, ","))
	_, err := db.Exec(sql)
	if err != nil {
		panic(err)
	}
}

func (ds *DatabaseSchema) Insert(db *sql.DB, fieldData []interface{}) {
	if ds.batcher == nil {
		ds.CreateTable(db)
		ds.batcher = makeInsertBatcher(db, ds.Name, ds.Fields)
	}
	ds.batcher.Insert(fieldData)
}