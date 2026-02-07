# res://addons/audio_editor/timeline_editor.gd
@tool
extends Control

var current_project: AudioProject
var pixels_per_second: float = 50.0
var track_height: float = 80.0
var wave_amplitude: float = 40.0
var step = 256

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	update()

func update() -> void:
	queue_redraw()

func _draw() -> void:
	if not current_project: return
	var keys = current_project.timeline_data.keys()
	keys.sort()
	for track_key in keys:
		var t := int(track_key)
		var y_offset := t * track_height
		# track background
		draw_rect(Rect2(0, y_offset, size.x, track_height), Color(0.06, 0.06, 0.06))
		# track header label
		if get_theme_font("font", "Label"):
			draw_string(get_theme_font("font", "Label"), Vector2(8, y_offset + 18), "Track %d" % t, 0, 1, 16, Color(1,1,1))
		for clip in current_project.timeline_data[track_key]:
			var stream = clip.get("stream", null)
			var position := float(clip.get("position", 0))
			var x := position * pixels_per_second
			var width := 100.0
			# Attempt to compute width from stream length if available
			if stream:
				if stream is AudioStreamMP3 and stream.has_method("get_length"):
					width = stream.get_length() * pixels_per_second
				elif stream is AudioStreamWAV and stream.has_method("get_length"):
					width = stream.get_length() * pixels_per_second
				elif stream is AudioStreamOggVorbis and stream.has_method("get_length"):
					width = stream.get_length() * pixels_per_second
			draw_rect(Rect2(x, y_offset + 10, width, track_height - 20), Color(0.18, 0.45, 0.8))
			# Attempt a lightweight waveform rendering for WAVs
			if stream and stream is AudioStreamWAV and stream.data and stream.data.size() > 0:
				var data = stream.data
				var mix_rate = stream.mix_rate
				var points = PackedVector2Array()
				var sample_step = max(1, int(data.size() / step))
				for i in range(0, data.size(), sample_step * 2): # s16 pairs
					var s = data.decode_s16(i) / 32768.0
					var px = x + (i / float(mix_rate)) * pixels_per_second
					points.append(Vector2(px, y_offset + track_height/2 + (s * wave_amplitude)))
				if points.size() > 1:
					draw_polyline(points, Color.AQUAMARINE, 1.0)

# --- Drag and Drop Logic ---

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Only allow dropping if data contains files
	return true
	#return typeof(data) == TYPE_DICTIONARY and data.get("type") == "files"

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var files = data.get("files", [])
	var track_idx = int(at_position.y / track_height)
	var drop_time = at_position.x / pixels_per_second
	for file_path in files:
		var stream = load(file_path)
		if stream and stream is AudioStream:
			if current_project:
				current_project.add_clip_to_timeline(track_idx, stream, drop_time)
