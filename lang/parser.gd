const Scanner = preload("res://lang/scanner.gd")
const Token = Scanner.Token
const t = Scanner.TokenType
const Ast = preload("res://lang/ast.gd")
const Lox = preload("res://lang/lox.gd")

var _tokens: Array[Token]
var _current = 0


func _init(tokens: Array[Token]) -> void:
	_tokens = tokens


func parse() -> Ast.AstNode:
	var expr := _parse_expression()
	return expr


func _parse_expression() -> Ast.Expr:
	return _parse_equality()


func _parse_equality() -> Ast.Expr:
	return _parse_binary_leftassoc(
		_parse_comparison, [t.BANG_EQUAL, t.EQUAL_EQUAL])


func _parse_comparison() -> Ast.Expr:
	return _parse_binary_leftassoc(
		_parse_term, [t.GREATER, t.GREATER_EQUAL, t.LESS, t.LESS_EQUAL])


func _parse_term() -> Ast.Expr:
	return _parse_binary_leftassoc(
		_parse_factor, [t.MINUS, t.PLUS])


func _parse_factor() -> Ast.Expr:
	return _parse_binary_leftassoc(
		_parse_unary, [t.SLASH, t.STAR])


func _parse_unary() -> Ast.Expr:
	if _match([t.BANG, t.MINUS]):
		var op := _previous()
		var right := _parse_unary()
		return Ast.UnaryExpr.new(right, op.type)
	return _parse_primary()


func _parse_primary() -> Ast.Expr:
	if _match([t.FALSE]): return Ast.lit(false)
	if _match([t.TRUE]): return Ast.lit(true)
	if _match([t.NIL]): return Ast.lit(null)

	if _match([t.NUMBER, t.STRING]):
		return Ast.lit(_previous().literal)
	
	if _match([t.LEFT_PAREN]):
		var expr := _parse_expression()
		_consume(t.RIGHT_PAREN, "Expect ')' after expression.")
		return Ast.group(expr)
	_error(_peek(), "Invalid primary expression")
	return null


func _match(types: Array[t]) -> bool:
	for tok in types:
		if _check(tok):
			_advance()
			return true
	
	return false


func _consume(type: t, msg: String) -> TokOpt:
	if _check(type): return top(_advance())
	return _error(_peek(), msg)


func _check(type: t) -> bool:
	if _is_at_end(): return false
	return _peek().type == type


func _advance() -> Token:
	if not _is_at_end():
		_current += 1
	return _previous()


func _is_at_end() -> bool:
	return _peek().type == t.EOF


func _peek() -> Token:
	return _tokens[_current]


func _previous() -> Token:
	return _tokens[_current - 1]


func _error(tok: Token, msg: String) -> TokOpt:
	Lox.error_t(tok, msg)
	return top(tok, ERR_PARSE_ERROR)


func _synchronise() -> void:
	_advance()

	while not _is_at_end():
		if _previous().type == t.SEMICOLON:
			return
		
		match _peek().type:
			t.CLASS, t.FUN, t.VAR, t.FOR, t.IF, t.WHILE, t.PRINT, t.RETURN:
				return
		
		_advance()


func _parse_binary_leftassoc(higher: Callable, tokens: Array[t]) -> Ast.Expr:
	var expr: Ast.Expr = higher.call()

	while _match(tokens):
		var op := _previous()
		var right: Ast.Expr = higher.call()
		expr = Ast.BinaryExpr.new(expr, op.type, right)
	
	return expr


class TokOpt:
	var tok: Token
	var err := Error.OK


	func _init(_t: Token, _e: Error) -> void:
		tok = _t
		err = _e


static func top(tok: Token, err: Error = OK) -> TokOpt:
	return TokOpt.new(tok, err)
