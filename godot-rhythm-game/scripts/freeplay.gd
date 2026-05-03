extends Control

@onready var song_list = $ScrollContainer/SongList
@onready var cover_frame = $CoverFrame
@onready var cover_image = $CoverFrame/CoverImage
@onready var song_name_label = $SongInfo/SongName
@onready var bpm_label = $SongInfo/BPM
@onready var vinyl = $Vinyl
@onready var vinyl_center_image = $Vinyl/VinylCenter/VinylCenterImage
@onready var scroll_indicator = $ScrollIndicator
@onready var scroll_container = $ScrollContainer
@onready var audio_player = $AudioStreamPlayer
@onready var easy_btn = $Difficulties/EasyBtn
@onready var hard_btn = $Difficulties/HardBtn
@onready var best_score_label = $"Best Score"

var chart_data: Dictionary = {}
var all_songs: Array = []
var selected_song_id: String = ""
var last_selected_btn: Button = null

var cover_base_pos: Vector2 = Vector2.ZERO
var cover_base_rot: float = 0.0

func _ready() -> void:
	cover_base_pos = cover_frame.position
	load_songs()
	
	if scroll_container.get_v_scroll_bar():
		scroll_container.get_v_scroll_bar().hide()

func load_songs() -> void:
	var dir = DirAccess.open("res://charts")
	var added_songs = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var raw_name = file_name.replace(".json", "")
				var base_name = raw_name.replace("_easy", "").replace("_hard", "") 
				if not base_name in added_songs:
					added_songs.append(base_name)
					all_songs.append(base_name)
					add_song_button(base_name)
			file_name = dir.get_next()

func _process(delta: float) -> void:
	if audio_player.playing:
		vinyl.rotation += delta * 2.0
	else:
		vinyl.rotation = lerp_angle(vinyl.rotation, 0.0, delta * 3.0)
		
	
	var sb = scroll_container.get_v_scroll_bar()
	if sb and sb.max_value > sb.page:
		var ratio = sb.value / (sb.max_value - sb.page)
		var inner_y = lerp(150.0, 600.0 - 50.0, ratio)
		scroll_indicator.position.y = inner_y
		scroll_indicator.size.y = 50.0

func add_song_button(chart_name: String) -> void:
	var btn = Button.new()
	btn.text = chart_name.capitalize()
	btn.add_theme_font_size_override("font_size", 24)
	btn.custom_minimum_size = Vector2(350, 60)
	
	
	var file = FileAccess.open("res://charts/" + chart_name + ".json", FileAccess.READ)
	if not file: file = FileAccess.open("res://charts/" + chart_name + "_easy.json", FileAccess.READ)
	if not file: file = FileAccess.open("res://charts/" + chart_name + "_hard.json", FileAccess.READ)
	
	var custom_color = Color(0.2, 0.2, 0.2, 1)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data.has("color"):
				custom_color = Color(data["color"])

	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = custom_color
	stylebox.border_width_left = 4
	stylebox.border_width_right = 4
	stylebox.border_width_top = 4
	stylebox.border_width_bottom = 4
	stylebox.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal", stylebox)
	
	var hover = stylebox.duplicate()
	hover.bg_color = custom_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = stylebox.duplicate()
	pressed.bg_color = custom_color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.pressed.connect(func(): _on_song_selected(chart_name, btn))

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_child(btn)
	song_list.add_child(margin)

func _on_song_selected(chart_name: String, btn: Button) -> void:
	selected_song_id = chart_name
	
	
	if last_selected_btn and is_instance_valid(last_selected_btn):
		var tw_old = get_tree().create_tween()
		tw_old.tween_property(last_selected_btn.get_parent(), "theme_override_constants/margin_left", 20, 0.2).set_trans(Tween.TRANS_QUAD)
	
	var tw = get_tree().create_tween()
	tw.tween_property(btn.get_parent(), "theme_override_constants/margin_left", 0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	last_selected_btn = btn
	
	
	var path = "res://charts/" + chart_name + ".json"
	if not FileAccess.file_exists(path): path = "res://charts/" + chart_name + "_easy.json"
	if not FileAccess.file_exists(path): path = "res://charts/" + chart_name + "_hard.json"
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			chart_data = json.get_data()
			if chart_data.has("song"):
				song_name_label.text = str(chart_data["song"])
			else:
				song_name_label.text = chart_name.capitalize()
			
			if chart_data.has("bpm"):
				bpm_label.text = str(chart_data["bpm"]) + " (BPM)"
			
			if chart_data.has("cover"):
				var img_path = chart_data["cover"]
				var c_tex: Texture2D = null
				
				
				if ResourceLoader.exists(img_path):
					c_tex = load(img_path)
					
				
				if c_tex == null and FileAccess.file_exists(img_path):
					var img = Image.new()
					var err = img.load(img_path)
					if err == OK:
						c_tex = ImageTexture.create_from_image(img)
					
				
				if c_tex == null:
					var fallback = "res://Game screen/assets/monitorbackground.jpg"
					if ResourceLoader.exists(fallback): c_tex = load(fallback)
					elif FileAccess.file_exists(fallback):
						var f_img = Image.new()
						if f_img.load(fallback) == OK:
							c_tex = ImageTexture.create_from_image(f_img)
					
				if c_tex:
					cover_image.texture = c_tex
					vinyl_center_image.texture = c_tex
			
			if chart_data.has("music"):
				audio_player.stream = load(chart_data["music"])
				audio_player.play()
	
	update_best_score_label(chart_name)
	
	
	var tw_cover = get_tree().create_tween()
	tw_cover.tween_property(cover_frame, "rotation_degrees", -5.0, 0.1)
	tw_cover.tween_property(cover_frame, "rotation_degrees", 0.0, 0.3).set_ease(Tween.EASE_OUT)

func update_best_score_label(chart_name: String) -> void:
	var global = get_node_or_null("/root/Global")
	if not global or best_score_label == null:
		return
	var easy_score = global.best_scores.get(chart_name + "_easy", 0)
	var hard_score = global.best_scores.get(chart_name + "_hard", 0)
	var normal_score = global.best_scores.get(chart_name, 0)
	
	var text = "Best Score\n"
	text += "Easy: " + str(easy_score) + "\n"
	text += "Hard: " + str(hard_score)
	best_score_label.text = text

func start_song(difficulty_suffix: String = ""):
	var global = get_node_or_null("/root/Global")
	if global and selected_song_id != "":
		
		var target = selected_song_id + difficulty_suffix
		if FileAccess.file_exists("res://charts/" + target + ".json"):
			global.selected_chart = target
		else:
			global.selected_chart = selected_song_id
			
		get_tree().change_scene_to_file("res://scenes/mainscene.tscn")

func _on_easy_btn_pressed() -> void:
	if selected_song_id != "":
		start_song("_easy")

func _on_hard_btn_pressed() -> void:
	if selected_song_id != "":
		start_song("_hard")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
