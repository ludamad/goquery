package goal

import ("database/sql")

type fieldType int
const (
	FIELD_TYPE_STRING fieldType = iota
	FIELD_TYPE_INT
)

type field struct {
	Name string
	Type fieldType
}

type DataSchema struct {
	Id         int
	Name       string
	Fields     []field
	Keys       []string
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
	return &DataContext{&DatabaseContext{nil,nil, map[int]*sql.Stmt{}}, []DataSchema{}}
}

func (s *DataContext) DefineData(name string, fieldNames, keys []string ) int {
	// TODO: All types are strings for now:
	fields := []field{}
	for _, fname := range fieldNames {
		fields = append(fields, field {fname, FIELD_TYPE_STRING})
	} 
	schema := makeSchema(len(s.Schemas), name, fields, keys)
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
