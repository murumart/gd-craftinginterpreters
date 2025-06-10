const Scanner = preload("res://lang/scanner.gd")
const Lox = preload("res://lang/lox.gd")
const Eval = preload("res://lang/evaluator.gd")

var _vals := {}


func define(name: String, value: Variant) -> void:
	_vals[name] = value


func getv(tok: Scanner.Token) -> Variant:
	if _vals.get(tok.lexeme):
		return _vals[tok.lexeme]
	return Eval.RuntimeError.new(tok, ERR_DOES_NOT_EXIST, "Undefined variable '%s'." % tok.lexeme)
