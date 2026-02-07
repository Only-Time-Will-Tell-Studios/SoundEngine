@tool
extends EditorPlugin

# This is the scene that will contain your DAW-like UI
const MAIN_PANEL_SCENE = preload("res://addons/SoundEngine/src/audio_main_panel.tscn")
var main_panel_instance

func _enter_tree() -> void:
	# 1. Instantiate the UI
	main_panel_instance = MAIN_PANEL_SCENE.instantiate()
	
	# 2. Add it to the main editor screen container
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	
	# 3. Initially hide it (the editor handles visibility via _make_visible)
	_make_visible(false)
	
	# 4. Reorder Tabs
	var base_control: Control = get_editor_interface().get_base_control()
	var tab_container = base_control.find_child("EditorMainScreenButtons", true, false)
	if tab_container and tab_container is Container and tab_container.get_child_count() > 0:
		var last_idx = tab_container.get_child_count() - 1
		# Move the last tab closer to the start (clamped)
		tab_container.move_child(tab_container.get_child(last_idx), clamp(3, 0, last_idx))

func _exit_tree() -> void:
	# Clean up when the plugin is disabled
	if main_panel_instance:
		main_panel_instance.queue_free()

# Tells Godot this plugin has a main tab button at the top
func _has_main_screen() -> bool:
	return true

# Sets the text on the top tab button
func _get_plugin_name() -> String:
	return "Audio"

# Returns the icon for the tab (optional)
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("AudioStreamPlayer", "EditorIcons")

# Handles switching between tabs (e.g., clicking 2D then back to Audio)
func _make_visible(visible: bool) -> void:
	if main_panel_instance:
		main_panel_instance.visible = visible

# Heuristic to accept AudioProject resources saved as AudioStreamInteractive in .tres
func _is_audio_project_object(object: Object) -> bool:
	if not object:
		return false
	# Favor the proper class if available
	if object is AudioProject:
		return true
	# If it's an AudioStreamInteractive saved without the class registered, detect by API
	if object is AudioStreamInteractive:
		if object.has_method("add_clip_to_timeline") or object.has_method("add_track"):
			return true
		var td = object.get("timeline_data")
		if td != null:
			return true
	return false

func _handles(object: Object) -> bool:
	return _is_audio_project_object(object)

func _edit(object: Object) -> void:
	if _is_audio_project_object(object):
		main_panel_instance.current_project = object
		main_panel_instance.queue_redraw()
