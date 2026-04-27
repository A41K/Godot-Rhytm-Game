extends Node2D
class_name RhythmEngine

@export var bpm: float = 120.0
@export var scroll_speed: float = 300.0
@export var chart_name: String = "test"
@export var center_position: Vector2 = Vector2(640, 360) 

var chart_data: Array = []
var time_elapsed: float = 0.0
var crotchet: float = 0.0
var current_beat: int = 0
var next_note_idx: int = 0
var is_playing: bool = false
var start_offset: float = -2.0 

var score: int = 0
var combo: int = 0
var misses: int = 0

var note_scene = preload("res://scenes/note.tscn")
var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	var global = get_node_or_null("/root/Global")
	if global and global.selected_chart != "":
		chart_name = global.selected_chart
		
	load_chart(chart_name)
	update_score_ui()

func add_hit(accuracy: float) -> void:

	if accuracy < 0.05:
		score += 300
		show_judgement_image("SICK")
	elif accuracy < 0.1:
		score += 150
		show_judgement_image("OK")
	elif accuracy < 0.2:
		score += 50
		show_judgement_image("BAD")
		add_miss(false) 
		return
	else:
		show_judgement_image("MISS")
		return add_miss(true)
		
	combo += 1
	update_score_ui()

func add_miss(is_full_miss: bool = true) -> void:
	combo = 0
	misses += 1
	score -= 100
	if is_full_miss:
		show_judgement_image("MISS")
	update_score_ui()

func show_judgement_image(judgement: String) -> void:
	var canvas = get_parent().get_node_or_null("CanvasLayer")
	if not canvas:
		return
	
	var tex_rect = TextureRect.new()
	var tex = load("res://images/" + judgement + ".png")
	if tex:
		tex_rect.texture = tex
	
	
	var viewport_size = get_viewport_rect().size
	if tex:
		tex_rect.position = Vector2(100, 100)
	else:
		tex_rect.position = Vector2(100, 100)
	
	
	canvas.add_child(tex_rect)
	var tween = create_tween()
	
	tween.tween_property(tex_rect, "position", tex_rect.position + Vector2(0, -50), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(tex_rect, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(tex_rect.queue_free)

func update_score_ui() -> void:
	var label = get_parent().get_node_or_null("CanvasLayer/ScoreLabel")
	if label:
		label.text = "Score: " + str(score) + " | Combo: " + str(combo) + " | Misses: " + str(misses)

func load_chart(c_name: String) -> void:
	var file_path = "res://charts/" + c_name + ".json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			bpm = float(data.get("bpm", 120.0))
			if data.has("scroll_speed"):
				scroll_speed = float(data["scroll_speed"])
			crotchet = 60.0 / bpm
			chart_data = data.get("notes", [])
			
			var song_name = data.get("song", "novacane")
			var audio_mp3 = "res://songs/" + song_name + ".mp3"
			var audio_ogg = "res://songs/" + song_name + ".ogg"
			var audio_flac = "res://songs/" + song_name + ".flac"
			if FileAccess.file_exists(audio_mp3):
				music_player.stream = load(audio_mp3)
			elif FileAccess.file_exists(audio_ogg):
				music_player.stream = load(audio_ogg)
			elif FileAccess.file_exists(audio_flac):
				music_player.stream = load(audio_flac)
			else:
				print("Music file not found: ", audio_mp3, " or ", audio_ogg)
			
			print("Loaded JSON chart '", c_name, "' with ", chart_data.size(), " notes. BPM: ", bpm)
			start_song()
		else:
			print("JSON Parse Error: ", json.get_error_message())
		return

	file_path = "res://charts/" + c_name + ".txt"
	if not FileAccess.file_exists(file_path):
		print("Chart not found: ", file_path)
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	crotchet = 60.0 / bpm
	
	content = content.replace("[", "").replace("]", "").replace(" ", "").replace("\n", "")
	if content.is_empty(): return
	
	var raw_notes = content.split(",")
	var auto_beat = 0.0
	for note_str in raw_notes:
		if note_str.length() >= 2:
			var type_num = int(note_str[0])
			var dir_char = note_str[1].to_lower()
			chart_data.append({"beat": auto_beat, "type": type_num, "dir": dir_char})
			auto_beat += 1.0 
			
	print("Loaded TXT chart '", c_name, "' with ", chart_data.size(), " notes.")
	start_song()

func start_song() -> void:
	time_elapsed = start_offset
	current_beat = 0
	next_note_idx = 0
	is_playing = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = true
		var escape_menu = load("res://scenes/escape_menu.tscn").instantiate()
		get_tree().root.add_child(escape_menu)

func _process(delta: float) -> void:
	if not is_playing: return
	

	if music_player.playing:
		time_elapsed = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	else:
		time_elapsed += delta
		
		if time_elapsed >= 0.0 and music_player.stream != null:
			music_player.play()
	

	while next_note_idx < chart_data.size():
		var note = chart_data[next_note_idx]

		var note_beat = float(note.get("beat", next_note_idx)) 
		var expected_time = note_beat * crotchet
		
	
		var spawn_lead_time = 2.0 
		
		if time_elapsed + spawn_lead_time >= expected_time:
			spawn_note(note, expected_time)
			next_note_idx += 1
		else:
			break

func spawn_note(note_data: Dictionary, hit_time: float) -> void:
	
	
	if not note_scene:
		print("Note scene not loaded!")
		return
		
	var new_note = note_scene.instantiate() as RhythmNote
	

	var target = center_position
	var main_scene = get_parent()
	
	var type_val = note_data.get("lane", note_data.get("type", 1))
	var type_int = 1
	

	var default_dir = ["u", "d"][randi() % 2]
	var dir_str = str(note_data.get("dir", default_dir))
	
	if typeof(type_val) == TYPE_STRING:
		var lane_str = type_val.to_lower()
		match lane_str:
			"up": type_int = 1
			"left": type_int = 2
			"down": type_int = 3
			"right": type_int = 4
			_: type_int = 1
	else:
		type_int = int(type_val)
	
	if main_scene:
		match type_int:
			1: # up
				var rec = main_scene.get_node_or_null("up")
				if rec: target = rec.global_position
			2: # left
				var rec = main_scene.get_node_or_null("left")
				if rec: target = rec.global_position
			3: # down
				var rec = main_scene.get_node_or_null("down")
				if rec: target = rec.global_position
			4: # right
				var rec = main_scene.get_node_or_null("right")
				if rec: target = rec.global_position
	
	add_child(new_note)
	new_note.setup(type_int, dir_str, hit_time, target, scroll_speed, self)
