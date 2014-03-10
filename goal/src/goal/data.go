package goal

import (
	"database/sql"
	"strings"
)

type field struct {
	Name string
	Type string
}

type DataSchema struct {
	Id     int
	Name   string
	Fields []field
	Keys   []string
}

func (schema *DataSchema) FieldLength() int { return len(schema.Fields) }
func (schema *DataSchema) KeyLength() int   { return len(schema.Keys) }

func makeSchema(id int, name string, fields []field, keys []string) DataSchema {
	return DataSchema{id, name, fields, keys}
}

type DataContext struct {
	*DatabaseContext
	Schemas []DataSchema
}

func MakeDataContext() *DataContext {
	return &DataContext{&DatabaseContext{nil, nil, map[int]*sql.Stmt{}}, []DataSchema{}}
}

func (s *DataContext) DefineData(name string, fieldNames, keys []string) int {
	fields := []field{}
	filteredKeys := []string{}

	for _, key := range keys {
		filteredKeys = append(filteredKeys, strings.Split(key, ":")[0])
	}

	for _, fname := range fieldNames {
		parts := strings.Split(fname, ":")
		typ := "TEXT" // Default to 'string' type
		if len(parts) >= 2 {
			typ = parts[1]
		}
		fields = append(fields, field{parts[0], typ})
	}
	schema := makeSchema(len(s.Schemas), name, fields, filteredKeys)
	s.Schemas = append(s.Schemas, schema)
	schema.CreateTable(s.DatabaseContext)
	return len(s.Schemas) - 1
}

func (s *DataContext) SaveData(databaseContext *DatabaseContext, tupleKind int, tuple []interface{}) {
	s.Schemas[tupleKind].Insert(databaseContext, tuple)
}

func (s *DataContext) SchemaFromName(name string) *DataSchema {
	for _, schema := range s.Schemas {
		if schema.Name == name {
			return &schema
		}
	}
	panic("No schema by name " + name + "!")
}
