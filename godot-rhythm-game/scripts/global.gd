extends Node

var selected_chart: String = "test"

# Stores the user's selected arrow type ("arrow", "circle", "triangle", "star")
var arrow_type: String = "arrow"

var best_scores: Dictionary = {}

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

func save_score(chart: String, score: int) -> void:
		if not best_scores.has(chart) or score > best_scores[chart]:
				best_scores[chart] = score
				_save_scores_to_disk()

func _save_scores_to_disk() -> void:
		var file = FileAccess.open("user://scores.json", FileAccess.WRITE)
		if file:
				file.store_string(JSON.stringify(best_scores))

func save_settings_to_disk() -> void:
		var data = { "master": master_volume, "music": music_volume, "sfx": sfx_volume }
		var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
		if file: file.store_string(JSON.stringify(data))

func load_settings_from_disk() -> void:
		if FileAccess.file_exists("user://settings.json"):
				var file = FileAccess.open("user://settings.json", FileAccess.READ)
				if file:
						var data = JSON.parse_string(file.get_as_text())
						if typeof(data) == TYPE_DICTIONARY:
								master_volume = data.get("master", 1.0)
								music_volume = data.get("music", 1.0)
								sfx_volume = data.get("sfx", 1.0)

func _load_scores_from_disk() -> void:
		if FileAccess.file_exists("user://scores.json"):
				var file = FileAccess.open("user://scores.json", FileAccess.READ)
				if file:
						var data = JSON.parse_string(file.get_as_text())
						if typeof(data) == TYPE_DICTIONARY:
								best_scores = data

func _init():
		_load_scores_from_disk()
		load_settings_from_disk()

func _ready():
		_setup_audio_buses()

func _setup_audio_buses():
		if AudioServer.get_bus_count() == 1:
				AudioServer.add_bus(1)
				AudioServer.set_bus_name(1, "Music")
				AudioServer.add_bus(2)
				AudioServer.set_bus_name(2, "SFX")
		apply_volumes()

func apply_volumes():
		var master_db = linear_to_db(master_volume) if master_volume > 0.001 else -80.0
		var music_db = linear_to_db(music_volume) if music_volume > 0.001 else -80.0
		var sfx_db = linear_to_db(sfx_volume) if sfx_volume > 0.001 else -80.0
		
		AudioServer.set_bus_volume_db(0, master_db) 
		var music_idx = AudioServer.get_bus_index("Music")
		if music_idx >= 0: AudioServer.set_bus_volume_db(music_idx, music_db)
		var sfx_idx = AudioServer.get_bus_index("SFX")
		if sfx_idx >= 0: AudioServer.set_bus_volume_db(sfx_idx, sfx_db)

var achievements = {
		"first_note": {
				"title": "First Steps",
				"description": "Hit your first note.",
				"unlocked": false
		},
		"full_combo": {
				"title": "Full Combo!",
				"description": "Complete a song without missing.",
				"unlocked": false
		},
		"play_story": {
				"title": "Story Time",
				"description": "Click on Story Mode.",
				"unlocked": false
		}
}

func unlock_achievement(id: String) -> void:
		if achievements.has(id) and not achievements[id]["unlocked"]:
				achievements[id]["unlocked"] = true
				show_achievement_popup(achievements[id])

func show_achievement_popup(data: Dictionary) -> void:
		var canvas = CanvasLayer.new()
		canvas.layer = 100 
		add_child(canvas)
		
		var panel = PanelContainer.new()
		canvas.add_child(panel)
		
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.8, 0.3)
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.corner_radius_bottom_left = 5
		panel.add_theme_stylebox_override("panel", style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(margin)
		
		var vbox = VBoxContainer.new()
		margin.add_child(vbox)
		
		var title = Label.new()
		title.text = "Achievement Unlocked!"
		title.add_theme_color_override("font_color", Color(1, 1, 0))
		vbox.add_child(title)
		
		var name_label = Label.new()
		name_label.text = data["title"]
		vbox.add_child(name_label)
		
		
		panel.size = Vector2(250, 70)
		panel.position = Vector2(-300, 20)
		
	  
		var tween = create_tween()
		tween.tween_property(panel, "position", Vector2(20, 20), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_interval(3.0)
	   
		tween.tween_property(panel, "position", Vector2(-300, 20), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		tween.tween_callback(canvas.queue_free)
