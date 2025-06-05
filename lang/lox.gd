const Scanner = preload("res://lang/scanner.gd")
const Parser = preload("res://lang/parser.gd")
const Ast = preload("res://lang/ast.gd")
const Eval = preload("res://lang/evaluator.gd")

static var _interpreter = Eval.new()
static var _line_input_method: Callable
static var _had_error := false
static var _had_runtime_error := false


static func main(args: PackedStringArray) -> Error:
	if args.size() > 1:
		print("Usage: jlox [script]")
		return ERR_UNCONFIGURED
	
	if args.size() == 1:
		return _run_file(args[0])
	
	return await _run_prompt()


static func _run_file(path: String) -> Error:
	var program: String = FileAccess.get_file_as_string(path)
	return _run(program)


static func _run_prompt() -> Error:
	while true:
		var line: String = await _line_input_method.call()
		if not line:
			break
		var _err := _run(line)
	return OK


static func _run(program: String) -> Error:
	var scanner := Scanner.new(program)
	var tokens := scanner.scan_tokens()

	var parser := Parser.new(tokens)
	var ast := parser.parse()

	if _had_error:
		return FAILED
	
	print(_interpreter.interpret(ast))
	if _had_runtime_error:
		return FAILED

	return OK


static func error(line: int, message: String) -> void:
	_report(line, "", message)


static func error_t(tok: Scanner.Token, message: String) -> void:
	if tok.type == Scanner.TokenType.EOF:
		_report(tok.line, " at end", message)
	else:
		_report(tok.line, " at '" + tok.lexeme + "'", message)


static func runtime_error(err: Eval.RuntimeError) -> void:
	printerr(err.msg + "\n[line " + str(err.tok.line) + ":" + str(err.tok.column) + "] " + err.tok.lexeme)
	push_error(err.msg + "\n[line " + str(err.tok.line) + ":" + str(err.tok.column) + "] " + err.tok.lexeme)
	_had_runtime_error = true


static func _report(line: int, where: String, message: String) -> void:
	printerr("[line ", line, "] Error", where, ": ", message)
	push_error("[line ", line, "] Error", where, ": ", message)
	_had_error = true


static func not_implemented() -> Error:
	assert(false, "Implement me")
	return ERR_METHOD_NOT_FOUND
