package test

type I interface {
	Requirement1()
	Requirement2(int) int
}

type A int
type B int
type C int

func (_ A) Requirement1() {}
func (_ B) Requirement1() {}

func (_ A) Requirement2(_ int) int { return 1 }
func (_ C) Requirement2(_ int) int { return 1 }

type Embedded struct {
	field int
}

func (_ Embedded) Requirement1() {}

type Complex struct {
	Embedded
}

func (_ Complex) Requirement2(_ int) int { return 1 }