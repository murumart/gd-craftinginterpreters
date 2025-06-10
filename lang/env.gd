const Scanner = preload("res://lang/scanner.gd")
const Lox = preload("res://lang/lox.gd")
const Eval = preload("res://lang/evaluator.gd")
const Env = preload("res://lang/env.gd")

var _enclosing: Env = null
var _vals := {}


func _init(enclosing: Env = null) -> void:
	_enclosing = enclosing


func define(name: String, value: Variant) -> void:
	_vals[name] = value


func getv(name: Scanner.Token) -> Variant:
	if _vals.get(name.lexeme):
		return _vals[name.lexeme]

	if _enclosing != null:
		return _enclosing.getv(name)
		
	return Eval.RuntimeError.new(name, ERR_DOES_NOT_EXIST, "Undefined variable '%s'." % name.lexeme)


func assign(name: Scanner.Token, value: Variant) -> void:
	if _vals.has(name.lexeme):
		_vals[name.lexeme] = value
		return
	
	if _enclosing != null:
		_enclosing.assign(name, value)
	
	Lox.error_t(name, "Undefined variable '%s'." % name.lexeme)
