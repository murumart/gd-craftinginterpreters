const Scanner = preload("res://lang/scanner.gd")
const tok_t = Scanner.TokenType
const Lox = preload("res://lang/lox.gd")


static func add(left: Expr, right: Expr) -> BinaryExpr:
	return BinaryExpr.new(left, tok_t.PLUS, right)


static func sub(left: Expr, right: Expr) -> BinaryExpr:
	return BinaryExpr.new(left, tok_t.MINUS, right)


static func mul(left: Expr, right: Expr) -> BinaryExpr:
	return BinaryExpr.new(left, tok_t.STAR, right)


static func div(left: Expr, right: Expr) -> BinaryExpr:
	return BinaryExpr.new(left, tok_t.SLASH, right)


static func neg(a: Expr) -> UnaryExpr:
	return UnaryExpr.new(a, tok_t.MINUS)


static func notb(a: Expr) -> UnaryExpr:
	return UnaryExpr.new(a, tok_t.BANG)


static func lit(a: Variant) -> LiteralExpr:
	return LiteralExpr.new(a)


static func group(a: Expr) -> GroupingExpr:
	return GroupingExpr.new(a)


class AstNode:
	var _children: Array[AstNode]


	func _init(childre_: Array[AstNode]) -> void:
		_children = childre_
	

	func get_children() -> Array[AstNode]:
		var arr: Array[AstNode] = _children.duplicate()
		return arr
	

	func accept(_visitor: AbstractAstVisitor) -> Variant:
		return Lox.not_implemented()


class Expr extends AstNode:
	pass


class BinaryExpr extends Expr:
	var _operator: tok_t


	func _init(left: Expr, op: tok_t, right: Expr) -> void:
		super ([left, right])
		_operator = op
	

	func get_left() -> Expr:
		return _children[0]
	

	func get_right() -> Expr:
		return _children[1]
	

	func get_operator() -> tok_t:
		return _operator
	

	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_binary_expr(self)


class UnaryExpr extends Expr:
	var _operator: tok_t


	func _init(target: Expr, op: tok_t) -> void:
		super ([target])
		_operator = op
	

	func get_target() -> Expr:
		return _children[0]
	

	func get_operator() -> tok_t:
		return _operator
	

	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_unary_expr(self)


class GroupingExpr extends Expr:
	func _init(expr: Expr) -> void:
		super ([expr])
	

	func get_expr() -> Expr:
		return _children[0]
	

	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_grouping_expr(self)
	

class LiteralExpr extends Expr:
	var _type: Variant.Type
	var _value: Variant


	func _init(varnt: Variant) -> void:
		_value = varnt
		match typeof(varnt):
			TYPE_STRING: _type = TYPE_STRING
			TYPE_INT, TYPE_FLOAT: _type = TYPE_FLOAT
			TYPE_BOOL: _type = TYPE_BOOL
			TYPE_NIL: _type = TYPE_NIL
			_: assert(false, "Unsuitable literal type " + type_string(typeof(varnt)))
	

	func get_value() -> Variant:
		return _value


	func get_type() -> Variant.Type:
		return _type


	func accept(v: AbstractAstVisitor) -> Variant:
		return v.visit_literal_expr(self)

# VISITOR

class AbstractAstVisitor:
	func visit(node: AstNode) -> Variant:
		return node.accept(self)
	

	func visit_binary_expr(_expr: BinaryExpr) -> Variant: return Lox.not_implemented()
	func visit_literal_expr(_expr: LiteralExpr) -> Variant: return Lox.not_implemented()
	func visit_unary_expr(_expr: UnaryExpr) -> Variant: return Lox.not_implemented()
	func visit_grouping_expr(_grouping_expr: GroupingExpr) -> Variant: return Lox.not_implemented()


class AstPrinter extends AbstractAstVisitor:
	var code := false
	
	func visit_binary_expr(expr: BinaryExpr) -> Variant:
		return (("" if code else "bin(")
			+ visit(expr.get_left())
			+" " + {
				tok_t.PLUS: "+",
				tok_t.MINUS: "-",
				tok_t.STAR: "*",
				tok_t.SLASH: "/",
			}[expr.get_operator()]
			+" " + visit(expr.get_right())
			+("" if code else ")")
		)
	
	
	func visit_literal_expr(expr: LiteralExpr) -> Variant:
		if expr.get_value() == null: return "nil"
		if expr.get_type() == TYPE_STRING:
			return "\"" + str(expr.get_value()) + "\""
		return str(expr.get_value())


	func visit_unary_expr(expr: UnaryExpr) -> Variant:
		return (("" if code else "un(")
			+
			{
				tok_t.BANG: "!",
				tok_t.MINUS: "-",
			}[expr.get_operator()]
			+"" + visit(expr.get_target())
			+("" if not code else ")")
		)


	func visit_grouping_expr(grouping_expr: GroupingExpr) -> Variant:
		return (
			("(" if code else "grouping(")
			+ visit(grouping_expr.get_expr()) + ")")
