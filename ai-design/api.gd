extends HTTPRequest

class_name API

const CommandsConfig = preload("res://addons/ai-design/json_data/commands.json")
const CachePath = "res://addons/ai-design/cache/"

const CommandTypeToRegex = {
	"CREATE_PRIMITIVE":"CREATE_PRIMITIVE\\s+(box|capsule|cylinder|prism|sphere|torus|plane), \\[(-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*)], \\[(-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*)], \\[(-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*)], \\[(-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*), (-?\\d+\\.?\\d*)]",
}


static func generate_initial_prompt(space_min: Vector3, space_max: Vector3) -> String:
	
	var initial_prompt = ""
	
	initial_prompt += "You are a translator you only understand given commands:\n"
	
	# iterate commands
	for i in range(CommandsConfig.data['commands'].size()):
		
		var command_name = CommandsConfig.data['commands'][0]['command_name']
		var command_description = CommandsConfig.data['commands'][0]['command_description']
		
		initial_prompt += command_name + " "
		
		# iterate arugments per command
		for j in range(CommandsConfig.data['commands'][i]['arguments'].size()):
			
			var argument_description = CommandsConfig.data['commands'][i]['arguments'][j]['description']
			
			initial_prompt += "<" + argument_description + ">"
			
			if j != CommandsConfig.data['commands'][i]['arguments'].size()-1:
				initial_prompt += ", "

	initial_prompt += "given a prompt interpret it using given command as much as possible.\n"
	initial_prompt += "it is also worth noting you operate in a 3d space with dimensions x,y,z that can range from "
	initial_prompt += str(space_min) + " to " + str(space_max) + ".\n"
	initial_prompt += "reply using only given commands and no other text from now on this is very important.\n"

	return initial_prompt


static func dir_contents(path: String) -> Array:
	
	var file_names: Array = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			file_names.append(file_name.split('.txt')[0])
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	return file_names


static func process_prompt(input_prompt: String, root_node: Node):
	var contents = dir_contents(CachePath)
	
	if input_prompt in contents:
		var cached = FileAccess.open(CachePath + input_prompt + '.txt', FileAccess.READ)
		
		var commands: Array[String] = []
		for command_line in cached.get_as_text().split('\n'):
			if command_line:
				commands.append(command_line)
		
		process_commands(commands, root_node)
		
	else:
		print("No method found of processing prompt")

static func process_commands(commands: Array[String], root_node: Node):

	for command in commands:
		var command_type = command.split(' ')[0]
		assert(command_type in CommandTypeToRegex.keys())
		
		var regex = RegEx.new()
		regex.compile(CommandTypeToRegex[command_type])
		var result = regex.search(command)

		if result:
			var process_func = Callable(API, command_type)
			process_func.call(result, root_node)
		else:
			print("Regex failed for command: " + command)

# ChatGPT Commands (from the commands.json file)

# Example: a box in the middle with 8 spheres around it in a circle like formation
static func CREATE_PRIMITIVE(regex_result: RegExMatch, root_node: Node):
	var object_type = regex_result.get_string(1)
	
	var object_position = Vector3(
		str_to_var(regex_result.get_string(2)),
		str_to_var(regex_result.get_string(3)),
		str_to_var(regex_result.get_string(4)),
	)
	
	var object_scale = Vector3(
		str_to_var(regex_result.get_string(5)),
		str_to_var(regex_result.get_string(6)),
		str_to_var(regex_result.get_string(7)),
	)
	
	var object_orientation = Vector3(
		str_to_var(regex_result.get_string(8)),
		str_to_var(regex_result.get_string(9)),
		str_to_var(regex_result.get_string(10)),
	)
	
	var object_color = Color(
		str_to_var(regex_result.get_string(11)),
		str_to_var(regex_result.get_string(12)),
		str_to_var(regex_result.get_string(13)),
	)
	
	print(object_type)
	print(object_position)
	print(object_scale)
	print(object_orientation)
	print(object_color)
	
	var new_mesh = MeshInstance3D.new()
	new_mesh.position = object_position
	new_mesh.rotation = object_orientation
	new_mesh.scale = object_scale
	
	match object_type:
		'box':
			new_mesh.mesh = BoxMesh.new()
		'capsule':
			new_mesh.mesh = CapsuleMesh.new()
		'prism':
			new_mesh.mesh = PrismMesh.new()
		'cylinder':
			new_mesh.mesh = CylinderMesh.new()
		'sphere':
			new_mesh.mesh = SphereMesh.new()
		'torus':
			new_mesh.mesh = TorusMesh.new()
		'plane':
			new_mesh.mesh = PlaneMesh.new()
		_:
			print("WARNING: No matching object type found for " + object_type + "using quad instead")
			new_mesh.mesh = QuadMesh.new()

	var material = StandardMaterial3D.new()
	material.albedo_color = object_color
	new_mesh.mesh.surface_set_material(0, material)

	root_node.add_child(new_mesh)
	new_mesh.set_owner(root_node)
