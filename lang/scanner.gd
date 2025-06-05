const Lox := preload("res://lang/lox.gd")

enum TokenType {
	# single-char
	LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
	COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR,

	# One or two character _tokens.
	BANG, BANG_EQUAL,
	EQUAL, EQUAL_EQUAL,
	GREATER, GREATER_EQUAL,
	LESS, LESS_EQUAL,

	# Literals.
	IDENTIFIER, STRING, NUMBER,

	# Keywords.
	AND, CLASS, ELSE, FALSE, FUN, FOR, IF, NIL, OR,
	PRINT, RETURN, SUPER, THIS, TRUE, VAR, WHILE,

	EOF
}

const KEYWORDS: Dictionary[String, TokenType] = {
	"and": TokenType.AND,
	"class": TokenType.CLASS,
	"else": TokenType.ELSE,
	"false": TokenType.FALSE,
	"for": TokenType.FOR,
	"fun": TokenType.FUN,
	"if": TokenType.IF,
	"nil": TokenType.NIL,
	"or": TokenType.OR,
	"print": TokenType.PRINT,
	"return": TokenType.RETURN,
	"super": TokenType.SUPER,
	"this": TokenType.THIS,
	"true": TokenType.TRUE,
	"var": TokenType.VAR,
	"while": TokenType.WHILE,
}

var _source: String
var _tokens: Array[Token] = []

var _start: int = 0
var _current: int = 0
var _line: int = 0
var _column: int = 0


func _init(program: String) -> void:
	_source = program


func scan_tokens() -> Array[Token]:
	const t = TokenType

	while !_is_at_end():
		_start = _current
		_scan_token()

	_tokens.push_back(Token.new(t.EOF, "", null, _line))
	return _tokens


func _scan_token() -> void:
	const t = TokenType

	var c: String = _advance()
	match c:
		"(": _add_token(t.LEFT_PAREN)
		")": _add_token(t.RIGHT_PAREN)
		"{": _add_token(t.LEFT_BRACE)
		"}": _add_token(t.RIGHT_BRACE)
		",": _add_token(t.COMMA)
		".": _add_token(t.DOT)
		"-": _add_token(t.MINUS)
		"+": _add_token(t.PLUS)
		";": _add_token(t.SEMICOLON)
		"*": _add_token(t.STAR)

		"!": _add_token(t.BANG_EQUAL if _match("=") else t.BANG)
		"=": _add_token(t.EQUAL_EQUAL if _match("=") else t.EQUAL)
		"<": _add_token(t.LESS_EQUAL if _match("=") else t.LESS)
		">": _add_token(t.GREATER_EQUAL if _match("=") else t.GREATER)

		"/":
			# skip comments to the end of the line
			if _match("/"):
				while _peek() != "\n" and not _is_at_end():
					_advance()
			else:
				_add_token(t.SLASH)
		
		" ", "\r", "\t": pass
		"\n": _advance_line()

		"\"": _scan_string()

		_:
			if _is_digit(c):
				_scan_number()
			elif _is_alpha(c):
				_scan_identifier()
			else:
				Lox.error(_line, "Unexpected character " + c)


func _scan_string() -> void:
	while _peek() != "\"" and not _is_at_end():
		if _peek() == "\n":
			_advance_line()
		_advance()
	
	if _is_at_end():
		Lox.error(_line, "Unterminated string")
		return
	
	_advance()

	var value := substr(_source, _start + 1, _current - 1)
	_add_token(TokenType.STRING, value)


func _scan_number() -> void:
	while _is_digit(_peek()):
		_advance()
	
	if _peek() == "." and _peek_next().is_valid_int():
		_advance()
	
		while _is_digit(_peek()):
			_advance()
	
	_add_token(TokenType.NUMBER, float(substr(_source, _start, _current)))


func _scan_identifier() -> void:
	while _is_alphanumeric(_peek()):
		_advance()
	
	var text := substr(_source, _start, _current)
	var type: TokenType = KEYWORDS.get(text, -1)

	if type == -1:
		type = TokenType.IDENTIFIER
	
	_add_token(type)


func _match(expected: String) -> bool:
	#if _is_at_end(): return false
	#if _source[_current] != expected: return false
	return false if _peek() != expected else [_advance(), true][1]

	#_current += 1
	#return true


func _peek():
	if _is_at_end():
		return char(0)
	return _source[_current]


func _peek_next():
	if _current + 1 >= _source.length():
		return char(0)
	return _source[_current + 1]


func _is_at_end() -> bool:
	return _current >= _source.length()


func _advance() -> String:
	var c := _source[_current]
	_current += 1
	_column += 1
	return c


func _advance_line() -> int:
	_line += 1
	_column = 0
	return _line


func _add_token(t: TokenType, l: Variant = null) -> void:
	var text := substr(_source, _start, _current)
	_tokens.push_back(Token.new(t, text, l, _line, _column))


func _is_digit(chara: String) -> bool:
	if not chara: return false
	var c: int = chara.unicode_at(0)
	var c0 = "0".unicode_at(0)
	return c >= c0 and c <= c0 + 10


func _is_alpha(chara: String) -> bool:
	if not chara: return false
	var c: int = chara.unicode_at(0)
	var ca := "a".unicode_at(0)
	var cz := "z".unicode_at(0)
	var cA := "A".unicode_at(0)
	var cZ := "Z".unicode_at(0)
	return (c >= ca and c <= cz) or (c >= cA and c <= cZ) or chara == "_"


func _is_alphanumeric(chara: String) -> bool:
	return _is_alpha(chara) or _is_digit(chara)


static func substr(str_: String, start: int, end: int) -> String:
	return str_.substr(start, end - start)


class Token:
	var type: TokenType
	var lexeme: String
	var literal: Variant
	var line: int
	var column: int


	func _init(type_: TokenType, lexeme_: String, literal_: Variant, line_: int, column_: int = -1) -> void:
		type = type_
		lexeme = lexeme_
		literal = literal_
		line = line_
		column = column_
	

	func _to_string() -> String:
		return "TOKEN <" + TokenType.find_key(type) + "> \n\tLEX→→" + lexeme + "←←\n\tLIT→→" + str(literal) + "←←\n"
