package test1

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
