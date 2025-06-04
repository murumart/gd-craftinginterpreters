extends Node

const Lox := preload("res://lang/lox.gd")
const Ast := preload("res://lang/ast.gd")


func _ready() -> void:
	Lox.main(["test.lox"])

	var a: Ast.AstNode = Ast.mul(
		Ast.neg(Ast.lit(123)),
		Ast.group(Ast.lit(45.67))
	)
	var printer := Ast.AstPrinter.new()
	print(printer.visit(a))