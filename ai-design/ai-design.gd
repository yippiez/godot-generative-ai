@tool
extends EditorPlugin

var main_panel_dock

func _enter_tree():
	
	print(API.generate_initial_prompt(Vector3.ONE*-10, Vector3.ONE*10))
	
	# UI
	main_panel_dock = preload("res://addons/ai-design/main.tscn").instantiate()
	
	# Connect signal
	var prompt_input: LineEdit = main_panel_dock.get_child(0).get_node("PromptInput")
	prompt_input.text_submitted.connect(_on_prompt_input)
	
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, main_panel_dock)

func _exit_tree():
	remove_control_from_docks(main_panel_dock)
	main_panel_dock.free()
	
func _on_prompt_input(input_prompt):
	main_panel_dock.get_child(0).get_node("PromptInput").clear()

	# get_root_node is propagetd inside the static class API this is not ideal
	# but will work for now
	API.process_prompt(input_prompt, get_root_node())

func get_root_node() -> Node:
	return get_editor_interface().get_edited_scene_root()
