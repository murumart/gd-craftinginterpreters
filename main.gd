extends Control

const Lox := preload("res://lang/lox.gd")
const Ast := preload("res://lang/ast.gd")

@export var line: LineEdit
@export var output: RichTextLabel


func _ready() -> void:
	Lox._line_input_method = get_line_input
	Lox._line_output_method = get_line_output
	Lox.main([])


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_tree().quit()


func get_line_input() -> String:
	var prog: String = await line.text_submitted
	line.text = ""
	output.text += "[color=gray]" + prog + "[/color]\n"
	return prog


func get_line_output(string: String, err := false) -> void:
	if err: output.text += "[color=red]"
	output.text += string + "\n"
	if err: output.text += "[/color]"
