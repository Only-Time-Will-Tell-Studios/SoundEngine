@tool
class_name AudioProject
extends AudioStreamInteractive

# Dictionary structure: { "track_index": [ { "stream": AudioStream, "position": float }, ... ] }
@export var timeline_data: Dictionary = {}

# Internal container (transient) for spawned AudioStreamPlayers when playing inside a Node
var _player_container: Node = null

func add_clip_to_timeline(track: int, stream: AudioStream, position: float):
	if not timeline_data.has(track):
		timeline_data[track] = []
	timeline_data[track].append({"stream": stream, "position": position})
	# If currently playing inside a container, add a player for this incoming clip
	if _player_container and is_instance_valid(_player_container):
		_add_clip_player(_player_container, stream, position)

func add_track() -> void:
	var idx := 0
	while timeline_data.has(idx):
		idx += 1
	timeline_data[idx] = []
	ResourceSaver.save(self, resource_path)

func get_length() -> float:
	var max_time := 0.0
	for track_key in timeline_data.keys():
		for clip in timeline_data[track_key]:
			var stream = clip["stream"]
			var pos := float(clip["position"])
			var duration := 0.0
			if stream is AudioStreamMP3 and stream.has_method("get_length"):
				duration = stream.get_length()
			elif stream is AudioStreamWAV and stream.has_method("get_length"):
				duration = stream.get_length()
			elif stream is AudioStreamOggVorbis and stream.has_method("get_length"):
				duration = stream.get_length()
			# best-effort fallback omitted for complex/unknown stream types
			max_time = max(max_time, pos + duration)
	return max_time

func _add_clip_player(container: Node, stream: AudioStream, position: float) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.autoplay = false
	container.add_child(player)
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = position
	container.add_child(timer)
	timer.connect("timeout", Callable(player, "play"))
	timer.start()

# parent must be a Node to host players (e.g., the audio panel). This spawns players + timers.
func play(parent: Node) -> void:
	stop()
	if not parent:
		return
	var container := Node.new()
	container.name = "AudioProject_PlayerContainer"
	parent.add_child(container)
	_player_container = container
	for track_key in timeline_data.keys():
		for clip in timeline_data[track_key]:
			_add_clip_player(container, clip["stream"], float(clip["position"]))

func stop() -> void:
	if _player_container and is_instance_valid(_player_container):
		_player_container.queue_free()
	_player_container = null 
