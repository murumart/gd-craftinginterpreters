const Scanner = preload("res://lang/scanner.gd")
const tok_t = Scanner.TokenType
const Token = Scanner.Token
const Lox = preload("res://lang/lox.gd")


static func lit(a: Variant) -> LiteralExpr:
	return LiteralExpr.new(a)


static func group(a: Expr) -> GroupingExpr:
	return GroupingExpr.new(a)


# AST node definitions

class AstNode:
	var _children: Array[AstNode]


	func _init(childre_: Array[AstNode]) -> void:
		_children = childre_


	func get_children() -> Array[AstNode]:
		var arr: Array[AstNode] = _children.duplicate()
		return arr


	func accept(_visitor: AbstractAstVisitor) -> Variant:
		return Lox.not_implemented()


# EXPRESSION definitions

class Expr extends AstNode:
	pass


class BinaryExpr extends Expr:
	var _operator: Token


	func _init(left: Expr, op: Token, right: Expr) -> void:
		super ([left, right])
		_operator = op


	func get_left() -> Expr:
		return _children[0]


	func get_right() -> Expr:
		return _children[1]


	func get_operator() -> Token:
		return _operator


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_binary_expr(self)


class UnaryExpr extends Expr:
	var _operator: Token


	func _init(target: Expr, op: Token) -> void:
		super ([target])
		_operator = op


	func get_target() -> Expr:
		return _children[0]


	func get_operator() -> Token:
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


class VarExpr extends Expr:
	var _name: Token


	func _init(name: Token) -> void:
		_name = name


	func get_name() -> Token:
		return _name


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_var_expr(self)


class AssignExpr extends Expr:
	var _name: Token
	var _val: Expr


	func _init(name: Token, val: Expr) -> void:
		_name = name
		_val = val


	func get_val() -> Expr:
		return _val


	func get_name() -> Token:
		return _name


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_assign_expr(self)


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


class LogicalExpr extends Expr:
	var _left: Expr
	var _op: Token
	var _right: Expr


	func _init(left: Expr, op: Token, right: Expr) -> void:
		_left = left
		_op = op
		_right = right


	func get_left() -> Expr:
		return _left


	func get_op() -> Token:
		return _op


	func get_right() -> Expr:
		return _right


# STATEMENT definitions

class Stmt extends AstNode:
	pass


class BlockStmt extends Stmt:
	var _stmts: Array[Stmt]


	func _init(stmts: Array[Stmt]) -> void:
		_stmts = stmts


	func get_stmts() -> Array[Stmt]:
		return _stmts


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_block_stmt(self)


class ExprStmt extends Stmt:
	var _expr: Expr


	func _init(expr: Expr) -> void:
		_expr = expr


	func get_expr() -> Expr:
		return _expr


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_expr_stmt(self)


class IfStmt extends Stmt:
	var _condition: Expr
	var _then: Stmt
	var _else: Stmt


	func _init(condition: Expr, then_c: Stmt, else_c: Stmt = null) -> void:
		_condition = condition
		_then = then_c
		_else = else_c


	func get_condition() -> Expr:
		return _condition


	func get_then() -> Stmt:
		return _then


	func get_else() -> Stmt:
		return _else


class PrintStmt extends Stmt:
	var _expr: Expr


	func _init(expr: Expr) -> void:
		_expr = expr


	func get_expr() -> Expr:
		return _expr


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_print_stmt(self)


class VarStmt extends Stmt:
	var _name: Token
	var _initi: Expr


	func _init(name: Token, expr: Expr) -> void:
		_name = name
		_initi = expr


	func get_initi() -> Expr:
		return _initi


	func get_name() -> Token:
		return _name


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_var_stmt(self)


class WhileStmt extends Stmt:
	var _condition: Expr
	var _body: Stmt


	func _init(condition: Expr, body: Stmt) -> void:
		_condition = condition
		_body = body


	func get_condition() -> Expr:
		return _condition


	func get_body() -> Stmt:
		return _body


	func accept(visitor: AbstractAstVisitor) -> Variant:
		return visitor.visit_while_stmt(self)


# VISITOR

class AbstractAstVisitor:
	func visit(node: AstNode) -> Variant:
		var result: Variant = node.accept(self)
		return result


	func visit_binary_expr(_expr: BinaryExpr) -> Variant: return Lox.not_implemented()
	func visit_literal_expr(_expr: LiteralExpr) -> Variant: return Lox.not_implemented()
	func visit_unary_expr(_expr: UnaryExpr) -> Variant: return Lox.not_implemented()
	func visit_grouping_expr(_grouping_expr: GroupingExpr) -> Variant: return Lox.not_implemented()
	func visit_var_expr(_var_expr: VarExpr) -> Variant: return Lox.not_implemented()
	func visit_logical_expr(_logical_expr: LogicalExpr) -> Variant: return Lox.not_implemented()

	func visit_expr_stmt(_expr_stmt: ExprStmt) -> Variant: return Lox.not_implemented()
	func visit_if_stmt(_if_stmt: IfStmt) -> Variant: return Lox.not_implemented()
	func visit_block_stmt(_block_stmt: BlockStmt) -> Variant: return Lox.not_implemented()
	func visit_print_stmt(_print_stmt: PrintStmt) -> Variant: return Lox.not_implemented()
	func visit_var_stmt(_var_stmt: VarStmt) -> Variant: return Lox.not_implemented()
	func visit_while_stmt(_while_stmt: WhileStmt) -> Variant: return Lox.not_implemented()
	func visit_assign_expr(_assign_expr: AssignExpr) -> Variant: return Lox.not_implemented()


class AstPrinter extends AbstractAstVisitor:
	var code := false


	func do_program(stmts: Array[Stmt]) -> String:
		var st := ""
		for stmt in stmts:
			st += visit(stmt) + ";\n"
		return st


	func visit_print_stmt(print_stmt: PrintStmt) -> Variant:
		return "print " + visit(print_stmt.get_expr())


	func visit_expr_stmt(exprst: ExprStmt) -> Variant:
		return visit(exprst.get_expr())


	func visit_binary_expr(expr: BinaryExpr) -> Variant:
		return (("" if code else "bin(")
			+ visit(expr.get_left())
			+" " + {
				tok_t.PLUS: "+",
				tok_t.MINUS: "-",
				tok_t.STAR: "*",
				tok_t.SLASH: "/",
				tok_t.LESS: "<",
				tok_t.GREATER: ">",
				tok_t.LESS_EQUAL: "<=",
				tok_t.GREATER_EQUAL: ">=",
				tok_t.EQUAL_EQUAL: "==",
				tok_t.BANG_EQUAL: "!=",
			}[expr.get_operator().type]
			+" " + visit(expr.get_right())
			+ ("" if code else ")")
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
			}[expr.get_operator().type]
			+"" + visit(expr.get_target())
			+ ("" if not code else ")")
		)


	func visit_grouping_expr(grouping_expr: GroupingExpr) -> Variant:
		return (
			("(" if code else "grouping(")
			+ visit(grouping_expr.get_expr()) + ")")


	func visit_var_stmt(var_stmt: VarStmt) -> Variant:
		return "var " + visit(var_stmt.get_initi())
