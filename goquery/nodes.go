package goquery

import (
	"database/sql"

	"log"
	"go/ast"
	"go/token"
)

func (context *SymbolContext) DebugPrint() {
	ast.Print(context.fileSet, context.fileList())
}

func (context *SymbolContext) DatabaseInsert(db *sql.DB, conf Configuration) {
	// Collect token files in a map
	tokenFiles := map[string]*token.File{}

	context.fileSet.Iterate(func(file *token.File) bool {
		tokenFiles[file.Name()] = file
		return true
	})

	for filename, file := range context.nameToAstFile {
		currentScope := map[*ast.Object]bool{}

		for _, obj := range file.Scope.Objects {
			currentScope[obj] = true
		}
		ast.Inspect(file, func(n ast.Node) bool {
			tokenFile := tokenFiles[filename]
			if tokenFile == nil {
				log.Fatal("Assertion error: tokenFile != nil") 
			}
			state := _State{context, db, conf, file, tokenFile, currentScope}
			state.handleNode(n)
			return true
		})
	}
}

type _State struct {
	Context      *SymbolContext
	DB           *sql.DB
	Conf         Configuration
	File         *ast.File
	TokenFile    *token.File
	CurrentScope map[*ast.Object]bool
}

func (s *_State) exprRepr(expr ast.Expr) string {
	return s.Context.exprRepr(expr)
}

func (s *_State) position(node ast.Node) token.Position {
	return s.TokenFile.Position(node.Pos())
}

func (s *_State) packageName() string {
	return s.File.Name.Name
}

func (s *_State) handleNode(n ast.Node) {
	switch n.(type) {
	case *ast.FuncDecl:
		node, _ := n.(*ast.FuncDecl)
		s.handleBlockStatement(node.Body)
		signatureType := node.Type
		if node.Recv != nil {
			name := node.Name.Name
			recvType := node.Recv.List[0].Type
			decl := MethodDeclaration{name, s.exprRepr(signatureType), s.exprRepr(recvType), s.position(node)}
			decl.DBAdd(s.DB)
		} else {
			name := s.packageName() + "." + node.Name.Name
			decl := FuncDeclaration{name, s.exprRepr(signatureType), s.position(node)}
			decl.DBAdd(s.DB)
		}
	case *ast.Ident:
		node, _ := n.(*ast.Ident)
		if s.CurrentScope[node.Obj] {
			// Within local scope
			name := s.packageName() + "." + node.Name
			ref := Ref{name, s.position(node)}
			ref.DBAdd(s.DB)
		}

	case *ast.TypeSpec:
		node, _ := n.(*ast.TypeSpec)
		s.handleTypeSpecNode(node)
	}
}

// TODO: Figure out what to do about block statements
func (s *_State) handleBlockStatement(b *ast.BlockStmt) {
	//	for _, s := range b.List {
	//		context.handleStatement(db, conf, file, s)
	//	}
}

func (s *_State) handleTypeSpecNode(t *ast.TypeSpec) {
	name := s.packageName() + "." + t.Name.Name // A beauty
	decl := TypeDeclaration{name, s.exprRepr(t.Type), s.position(t)}
	decl.DBAdd(s.DB)
	switch t.Type.(type) {
	case *ast.InterfaceType:
		requirements := []InterfaceRequirement{}
		iface, _ := t.Type.(*ast.InterfaceType)
		for _, method := range iface.Methods.List {
			requiredName := method.Names[0].Name
			req := InterfaceRequirement{requiredName, s.exprRepr(method.Type), s.position(method)}
			requirements = append(requirements, req)
		}
		decl := InterfaceDeclaration{name, requirements, s.position(iface)}
		decl.DBAdd(s.DB)
	}
}

// The node types:

type InterfaceRequirement struct {
	Name, TypeRepr string
	Pos token.Position
}

type InterfaceDeclaration struct {
	Name         string
	Requirements []InterfaceRequirement
	Pos token.Position
}

type FuncDeclaration struct {
	Name, SignatureTypeRepr string
	Pos token.Position
}

type MethodDeclaration struct {
	Name, SignatureTypeRepr, ReceiverTypeRepr string // Can be '' == no receiver
	Pos token.Position
}

type TypeDeclaration struct {
	Name, TypeRepr string
	Pos token.Position
}

type Ref struct {
	Name string // The unique identifier being referenced
	Pos token.Position
}
