const Scanner = preload("res://lang/scanner.gd")
const Token = Scanner.Token
const t = Scanner.TokenType
const Ast = preload("res://lang/ast.gd")
const Lox = preload("res://lang/lox.gd")

var _tokens: Array[Token]
var _current = 0


func _init(tokens: Array[Token]) -> void:
	_tokens = tokens


func parse() -> Array[Ast.Stmt]:
	var stmts: Array[Ast.Stmt] = []
	while not _is_at_end():
		stmts.append(_parse_declaration())
	return stmts


func _parse_declaration() -> Ast.Stmt:
	var stmt: Ast.Stmt
	if _match([t.VAR]):
		stmt = _parse_var_declaration()
	else:
		stmt = _parse_statement()
	
	if stmt == null:
		_synchronise()
		return null
	return stmt


func _parse_expression() -> Ast.Expr:
	return _parse_assignment()


func _parse_assignment() -> Ast.Expr:
	var expr := _parse_or()

	if _match([t.EQUAL]):
		var equals := _previous()
		var value := _parse_assignment()

		if expr is Ast.VarExpr:
			var name: Token = expr.get_name()
			return Ast.AssignExpr.new(name, value)
		
		Lox.error_t(equals, "Invalid assignment target.")
	
	return expr


func _parse_or() -> Ast.Expr:
	var expr := _parse_and()

	while _match([t.OR]):
		var op := _previous()
		var right := _parse_and()
		expr = Ast.LogicalExpr.new(expr, op, right)

	return expr


func _parse_and() -> Ast.Expr:
	var expr := _parse_equality()

	while _match([t.AND]):
		var op := _previous()
		var right := _parse_equality()
		expr = Ast.LogicalExpr.new(expr, op, right)

	return expr


func _parse_statement() -> Ast.Stmt:
	if _match([t.FOR]): return _parse_for_statement()
	if _match([t.IF]): return _parse_if_statement()
	if _match([t.PRINT]): return _parse_print_statement()
	if _match([t.WHILE]): return _parse_while_statement()
	if _match([t.LEFT_BRACE]): return Ast.BlockStmt.new(_parse_block())
	return _parse_expression_statement()


func _parse_for_statement() -> Ast.Stmt:
	var e := _consume(t.LEFT_PAREN, "Expect '(' after 'for'.")
	if e.err != OK:
		return null
	
	var initialiser: Ast.Stmt
	if _match([t.SEMICOLON]):
		initialiser = null
	elif _match([t.VAR]):
		initialiser = _parse_var_declaration()
	else:
		initialiser = _parse_expression_statement()
	
	var condition: Ast.Expr = null
	if not _check(t.SEMICOLON):
		condition = _parse_expression()
	e = _consume(t.SEMICOLON, "Expect ';' after loop condition.")
	if e.err != OK:
		return null

	var increment: Ast.Expr = null
	if not _check(t.RIGHT_PAREN):
		increment = _parse_expression()
	e = _consume(t.RIGHT_PAREN, "Expect ')' after for clauses.")
	if e.err != OK:
		return null
	
	var body := _parse_statement()

	if increment != null:
		body = Ast.BlockStmt.new([body, Ast.ExprStmt.new(increment)])
	
	if condition == null:
		condition = Ast.LiteralExpr.new(true)
	body = Ast.WhileStmt.new(condition, body)

	if initialiser != null:
		body = Ast.BlockStmt.new([initialiser, body])

	return body


func _parse_if_statement() -> Ast.IfStmt:
	var e := _consume(t.LEFT_PAREN, "Expect '(' after 'if'.")
	if e.err != OK:
		return null
	var condition := _parse_expression()
	e = _consume(t.RIGHT_PAREN, "Expect ')' after 'condition'.")

	var then_b := _parse_statement()
	var else_b: Ast.Stmt = null
	if _match([t.ELSE]):
		else_b = _parse_statement()
	
	return Ast.IfStmt.new(condition, then_b, else_b)



func _parse_print_statement() -> Ast.PrintStmt:
	var val := _parse_expression()
	var err := _consume(t.SEMICOLON, "Expect ';' after value.")
	if err.err != OK:
		return null
	return Ast.PrintStmt.new(val)


func _parse_while_statement() -> Ast.WhileStmt:
	var e := _consume(t.LEFT_PAREN, "Expect '(' after 'while'.")
	if e.err != OK:
		return null
	var condition := _parse_expression()
	e = _consume(t.RIGHT_PAREN, "Expect ')' after 'condition'.")
	if e.err != OK:
		return null
	var body := _parse_statement()

	return Ast.WhileStmt.new(condition, body)


func _parse_var_declaration() -> Ast.Stmt:
	var name := _consume(t.IDENTIFIER, "Expect variable name.")
	if name.err != OK: return null

	var init: Ast.Expr = null
	if _match([t.EQUAL]):
		init = _parse_expression()
	
	var err := _consume(t.SEMICOLON, "Expect `;` after variable declaration.")
	if err.err != OK: return null
	return Ast.VarStmt.new(name.tok, init)


func _parse_expression_statement() -> Ast.ExprStmt:
	var val := _parse_expression()
	var err := _consume(t.SEMICOLON, "Expect ';' after expression.")
	if err.err != OK:
		return null
	return Ast.ExprStmt.new(val)


func _parse_block() -> Array[Ast.Stmt]:
	var stmts: Array[Ast.Stmt] = []

	while not _check(t.RIGHT_BRACE):
		stmts.push_back(_parse_declaration())
	
	var err := _consume(t.RIGHT_BRACE, "Expect '}' after block.")
	if err.err != OK:
		return []
	return stmts


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
		return Ast.UnaryExpr.new(right, op)
	return _parse_primary()


func _parse_primary() -> Ast.Expr:
	if _match([t.FALSE]): return Ast.lit(false)
	if _match([t.TRUE]): return Ast.lit(true)
	if _match([t.NIL]): return Ast.lit(null)

	if _match([t.NUMBER, t.STRING]):
		return Ast.lit(_previous().literal)
	
	if _match([t.IDENTIFIER]):
		return Ast.VarExpr.new(_previous())
	
	if _match([t.LEFT_PAREN]):
		var expr := _parse_expression()
		var err := _consume(t.RIGHT_PAREN, "Expect ')' after expression.")
		if err.err != OK:
			return null
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
		expr = Ast.BinaryExpr.new(expr, op, right)
	
	return expr


class TokOpt:
	var tok: Token
	var err := Error.OK


	func _init(_t: Token, _e: Error) -> void:
		tok = _t
		err = _e


static func top(tok: Token, err: Error = OK) -> TokOpt:
	return TokOpt.new(tok, err)
