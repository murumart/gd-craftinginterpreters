const Lox = preload("res://lang/lox.gd")
const Ast = preload("res://lang/ast.gd")
const AstNode = Ast.AstNode
const Scanner = preload("res://lang/scanner.gd")
const t = Scanner.TokenType
const Env = preload("res://lang/env.gd")


func interpret(stmts: Array[Ast.Stmt]) -> void:
	var visitor := Evaluator.new()
	for stmt in stmts:
		var result: Variant = visitor.execute(stmt)
		if result is RuntimeError:
			Lox.runtime_error(result)
			return


class Evaluator extends Ast.AbstractAstVisitor:
	var _env := Env.new()


	func evaluate(expr: Ast.Expr) -> Variant:
		return visit(expr)


	func execute(stmt: Ast.Stmt) -> Variant:
		return visit(stmt)


	func execute_block(stmts: Array[Ast.Stmt], env: Env) -> Variant:
		var prev := _env
		_env = env
		for stmt in stmts:
			var r: Variant = execute(stmt)
			if r is RuntimeError:
				Lox.runtime_error(r)
		_env = prev
		return null


	func visit_block_stmt(block_stmt: Ast.BlockStmt) -> Variant:
		execute_block(block_stmt.get_stmts(), Env.new(_env))
		return null


	func visit_expr_stmt(expr_stmt: Ast.ExprStmt) -> Variant:
		var ev: Variant = evaluate(expr_stmt.get_expr())
		if ev is RuntimeError: return ev
		return null


	func visit_if_stmt(if_stmt: Ast.IfStmt) -> Variant:
		if is_truthy(evaluate(if_stmt.get_condition())):
			execute(if_stmt.get_then())
		elif if_stmt.get_else() != null:
			execute(if_stmt.get_else())
		return null


	func visit_print_stmt(print_stmt: Ast.PrintStmt) -> Variant:
		var ev: Variant = evaluate(print_stmt.get_expr())
		if ev is RuntimeError: return ev
		Lox.output(str(ev))
		return null


	func visit_var_stmt(var_stmt: Ast.VarStmt) -> Variant:
		var val: Variant = null
		if var_stmt.get_initi() != null:
			val = evaluate(var_stmt.get_initi())

		_env.define(var_stmt.get_name().lexeme, val)
		return null


	func visit_while_stmt(stmt: Ast.WhileStmt) -> Variant:
		while is_truthy(evaluate(stmt.get_condition())):
			execute(stmt.get_body())
		return null


	func visit_assign_expr(assign_expr: Ast.AssignExpr) -> Variant:
		var val: Variant = evaluate(assign_expr.get_val())
		_env.assign(assign_expr.get_name(), val)
		return val


	func visit_binary_expr(binary_expr: Ast.BinaryExpr) -> Variant:
		var left: Variant = visit(binary_expr.get_left())
		var right: Variant = visit(binary_expr.get_right())
		if left is RuntimeError: return left
		if right is RuntimeError: return right
		match binary_expr.get_operator().type:
			t.PLUS:
				if left is String and right is String:
					return left + right
				if left is float and right is float:
					return left + right
				if left == null and right != null:
					return right
				if right == null and left != null:
					return left
				return RuntimeError.new(binary_expr.get_operator(), ERR_INVALID_PARAMETER, "Operands must be two numbers or two strings.")
			t.MINUS:
				var err := check_number_operands(binary_expr.get_operator(), left, right)
				if err != null: return err
				return left - right
			t.STAR:
				var err := check_number_operands(binary_expr.get_operator(), left, right)
				if err != null: return err
				return left * right
			t.SLASH:
				var err := check_number_operands(binary_expr.get_operator(), left, right)
				if err != null: return err
				if right == 0:
					return RuntimeError.new(binary_expr.get_operator(), ERR_INVALID_PARAMETER, "Division by zero")
				return left / right
			t.LESS:
				var err := check_number_operands(binary_expr.get_operator(), left, right)
				if err != null: return err
				return left < right
			t.LESS_EQUAL:
				var err := check_number_operands(binary_expr.get_operator(), left, right)
				if err != null: return err
				return left <= right
			t.GREATER:
				var err := check_number_operands(binary_expr.get_operator(), left, right)
				if err != null: return err
				return left > right
			t.GREATER_EQUAL:
				var err := check_number_operands(binary_expr.get_operator(), left, right)
				if err != null: return err
				return left >= right
			t.EQUAL_EQUAL: return left == right
			t.BANG_EQUAL: return left != right
		return null


	func visit_logical_expr(expr: Ast.LogicalExpr) -> Variant:
		var left: Variant = evaluate(expr.get_left())

		if expr.get_op().type == t.OR:
			if is_truthy(left): return left
		else:
			if not is_truthy(left): return left

		return evaluate(expr.get_right())


	func visit_literal_expr(literal_expr: Ast.LiteralExpr) -> Variant:
		return literal_expr.get_value()


	func visit_grouping_expr(grouping_expression: Ast.GroupingExpr) -> Variant:
		return visit(grouping_expression.get_expr())


	func visit_unary_expr(unary_expression: Ast.UnaryExpr) -> Variant:
		var target: Variant = visit(unary_expression.get_target())
		if target is RuntimeError: return target
		match unary_expression.get_operator().type:
			t.BANG: return not is_truthy(target)
			t.MINUS:
				var err := check_number_operand(unary_expression.get_operator(), target)
				if err != null: return err
				return -target
		return null


	func visit_var_expr(var_expr: Ast.VarExpr) -> Variant:
		return _env.getv(var_expr.get_name())


	func is_truthy(a: Variant) -> bool:
		if a is bool and a == false: return false
		if a == null: return false
		return true


	func check_number_operand(op: Token, oper: Variant) -> RuntimeError:
		if oper is float: return null
		return RuntimeError.new(op, ERR_INVALID_PARAMETER, "Operand must be a number.")


	func check_number_operands(op: Token, le: Variant, ri: Variant) -> RuntimeError:
		if le is float and ri is float: return null
		return RuntimeError.new(op, ERR_INVALID_PARAMETER, "Operands must be numbers.")


class RuntimeError:
	var tok: Scanner.Token
	var msg: String
	var err: Error


	func _init(tok_: Scanner.Token, err_: Error, msg_: String) -> void:
		tok = tok_
		err = err_
		msg = msg_
		breakpoint
