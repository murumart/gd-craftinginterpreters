extends Node

const Lox := preload("res://lang/lox.gd")
const Ast := preload("res://lang/ast.gd")


func _ready() -> void:
	Lox.main(["test.lox"])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
