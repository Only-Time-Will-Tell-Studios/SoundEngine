@tool
extends Control

const AUDIO_CLAZZ = &"AudioProject"

var _current_project: AudioProject = null

@onready var project_list := $HBox/LeftVBox/ProjectList
@onready var timeline := $HBox/RightVBox/TimelineContainer
@onready var file_dialog := $HBox/LeftVBox/FileDialog

func _ready() -> void:
	$HBox/LeftVBox/OpenButton.connect("pressed", Callable(self, "_on_open_pressed"))
	$HBox/LeftVBox/CreateButton.connect("pressed", Callable(self, "_on_create_pressed"))
	$HBox/LeftVBox/AddTrackButton.connect("pressed", Callable(self, "_on_add_track_pressed"))
	$HBox/LeftVBox/PlayButton.connect("pressed", Callable(self, "_on_play_pressed"))
	$HBox/LeftVBox/StopButton.connect("pressed", Callable(self, "_on_stop_pressed"))
	project_list.connect("item_selected", Callable(self, "_on_project_selected"))
	file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	# Default to scanning projects at start
	_scan_projects()
	
	EditorFileDialog

func _on_open_pressed() -> void:
	_scan_projects()

func _scan_projects() -> void:
	project_list.clear()
	var projects := _find_audio_projects("res://")
	for p in projects:
		project_list.add_item(p)

# Heuristic: Accept resources that are AudioProject OR AudioStreamInteractive with expected API/property
func _is_audio_project_resource(r: Resource) -> bool:
	if not r:
		return false
	if r is AudioProject:
		return true
	if r is AudioStreamInteractive:
		if r.has_method("add_clip_to_timeline") or r.has_method("add_track"):
			return true
		var td = r.get("timeline_data")
		if td != null:
			return true
	return false

func _find_audio_projects(path: String) -> Array:
	var results := []
	var dir := DirAccess.open(path)
	if not dir:
		return results
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if dir.current_is_dir(): 
			results.append_array(_find_audio_projects(path.path_join(f)))
		if f.to_lower().ends_with(".tres") or f.to_lower().ends_with(".res"):
			var res_path := path.path_join(f)
			var r := ResourceLoader.load(res_path)
			if r and _is_audio_project_resource(r):
				results.append(res_path)
		f = dir.get_next()
	dir.list_dir_end()
	return results

func _on_project_selected(index: int) -> void:
	var path = project_list.get_item_text(index)
	var res := ResourceLoader.exists(path, AUDIO_CLAZZ)
	if res:
		_current_project = ResourceLoader.load(path)
		timeline.current_project = _current_project
		timeline.update()

func _on_create_pressed() -> void:
	file_dialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.popup_centered_ratio(0.5)
 
func _on_file_selected(path: String) -> void:
	# Save new project if in save mode
	if file_dialog.mode == FileDialog.FILE_MODE_SAVE_FILE:
		var newproj := AudioProject.new()
		ResourceSaver.save(newproj, path)
		_scan_projects()
	else:
		var res := ResourceLoader.exists(path, AUDIO_CLAZZ)
		if res:
			_current_project = ResourceLoader.load(path)
			timeline.current_project = _current_project
			timeline.update()

func _on_add_track_pressed() -> void:
	if not _current_project:
		return
	_current_project.add_track()
	print("add track")
	timeline.update()

func _on_play_pressed() -> void:
	if not _current_project:
		return
	print("play")
	_current_project.play(self)

func _on_stop_pressed() -> void:
	if _current_project:
		_current_project.stop()
	print("stop")
	
# --- Drag and Drop Logic ---

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return true
