extends Control

@onready var song_list = $VBoxContainer/ScrollContainer/SongList

func _ready() -> void:
	load_songs()

func load_songs() -> void:
	var dir = DirAccess.open("res://charts")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var chart_name = file_name.replace(".json", "")
				add_song_button(chart_name)
			file_name = dir.get_next()

func add_song_button(chart_name: String) -> void:
	var btn = Button.new()
	btn.text = chart_name.capitalize() + "   ▶"
	btn.add_theme_font_size_override("font_size", 24)
	btn.custom_minimum_size = Vector2(0, 50)
	
	btn.pressed.connect(func(): _on_song_selected(chart_name))
	
	song_list.add_child(btn)

func _on_song_selected(chart_name: String) -> void:
	var global = get_node_or_null("/root/Global")
	if global:
		global.selected_chart = chart_name
	
	
	get_tree().change_scene_to_file("res://scenes/mainscene.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
