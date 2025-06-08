static func generical(
	abstract_script: Script,
	source_class: StringName,
	dest_class: StringName,
	output_path: String
) -> void:
	assert(abstract_script.get_script_signal_list().is_empty(), "no signals allowed")
	assert(abstract_script.get_script_property_list().is_empty(), "no properties allowed")

	var mdict := abstract_script.get_script_method_list()
	var methods: Array[Method]
	methods.assign(mdict.map(Method.from_dict))

	for method in methods:
		for arg in method.args:
			if arg.type == TYPE_OBJECT and arg.classn == source_class:
				arg.classn = dest_class
		if method.return_type == TYPE_OBJECT and method.return_class == source_class:
			method.return_class = dest_class
	
	var text := ""
	for method in methods:
		text += str(method) + "\n\n\n"
	
	var facsess := FileAccess.open(output_path, FileAccess.WRITE)
	facsess.store_string(text)
	facsess.close()
	

class Method:
	var name: StringName
	var args: Array[Arg]
	var return_type: Variant.Type
	var return_class: StringName


	func _init(
		name_: StringName,
		args_: Array[Arg],
		return_type_: Variant.Type,
		return_class_: StringName
	) -> void:
		name = name_
		args = args_
		return_type = return_type_
		return_class = return_class_


	func _to_string() -> String:
		var argsstr := ""
		for arg in args:
			argsstr += str(arg)
			if arg != args.back(): argsstr += ", "
		var returnstr := (StringName(type_string(return_type))
			if return_type != TYPE_OBJECT or return_class.is_empty()
			else return_class)
		return """func %s(%s) -> %s: return null # TODO implement""" % [name, argsstr, return_class]


	static func from_dict(dict: Dictionary) -> Method:
		var rgs: Array[Arg]
		rgs.assign(dict["args"].map(Arg.from_dict))
		return Method.new(
			dict["name"],
			rgs,
			dict["return"]["type"],
			dict["return"]["class_name"],
		)


	class Arg:
		var name: StringName
		var type: Variant.Type
		var classn: StringName


		func _init(name_: StringName, type_: Variant.Type, class_name_: StringName) -> void:
			name = name_
			type = type_
			classn = class_name_

		
		func _to_string() -> String:
			var st := name
			if type == TYPE_OBJECT and not classn.is_empty():
				st += ": " + classn
			else:
				st += ": " + type_string(type)
			return st
		

		static func from_dict(dict: Dictionary) -> Arg:
			return Arg.new(
				dict["name"],
				dict["type"],
				dict["class_name"],
			)
