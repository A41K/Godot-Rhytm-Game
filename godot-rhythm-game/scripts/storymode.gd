extends Control

@onready var day_list = $ScrollContainer/DayList
@onready var cover_image = $CoverFrame/CoverImage
@onready var cover_label = $CoverFrame/CoverLabel
@onready var day_name_label = $DayName
@onready var songs_list_label = $SongsList
@onready var best_score_label = $"Best Score"
@onready var scroll_indicator = $ScrollIndicator
@onready var scroll_container = $ScrollContainer

var selected_week = 0


var weeks = [
	{
		"name": "Day 2",
		"songs": ["novacane", "familyties"],
		"cover": preload("res://images/day2.png"),
		"score": 0,
		"color": Color(0.8, 0.4, 0.4)
	},
]

func _ready():
	populate_day_list()
	update_ui(0)
	
	
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll)

func populate_day_list():

	for child in day_list.get_children():
		child.queue_free()
		

	for i in range(weeks.size()):
		var btn = Button.new()
		btn.text = weeks[i]["name"]
		btn.custom_minimum_size = Vector2(0, 80)
		btn.add_theme_font_size_override("font_size", 32)
		
	
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.1, 0.1, 0.1, 1)
		normal_style.corner_radius_top_left = 15
		normal_style.corner_radius_top_right = 15
		normal_style.corner_radius_bottom_right = 15
		normal_style.corner_radius_bottom_left = 15
		
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = Color(0.25, 0.25, 0.25, 1)
		hover_style.border_width_bottom = 4
		hover_style.border_color = weeks[i]["color"]
		
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		btn.add_theme_stylebox_override("focus", hover_style)
		
		
		btn.pressed.connect(func(): update_ui(i))
		day_list.add_child(btn)

func update_ui(index: int):
	selected_week = index
	var week_data = weeks[index]
	

	day_name_label.text = week_data["name"]
	best_score_label.text = "Best Overall Score: " + str(week_data["score"])
	

	var song_text = "Songs:\n"
	for i in range(week_data["songs"].size()):
		song_text += str(i+1) + ". " + week_data["songs"][i].capitalize() + "\n"
	songs_list_label.text = song_text
	
	
	if week_data.get("cover"):
		cover_image.texture = week_data["cover"]
		cover_label.hide() 
	else:
		cover_image.texture = null
		cover_label.show()
		
func _on_scroll(value: float):
	
	var max_scroll = scroll_container.get_v_scroll_bar().max_value - scroll_container.size.y
	if max_scroll > 0:
		var ratio = value / max_scroll
		scroll_indicator.position.y = lerp(221.0, 503.0 - scroll_indicator.size.y, ratio)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")

func _on_easy_btn_pressed():
	start_story_run("easy")

func _on_hard_btn_pressed():
	start_story_run("hard")

func start_story_run(difficulty: String):

	var selected_data = weeks[selected_week]
	print("Starting Story Mode for %s on %s difficulty" % [selected_data["name"], difficulty])
	print("Playlist: ", selected_data["songs"])
	
	# Example transition setup:
	# Global.current_playlist = selected_data["songs"]
	# Global.current_difficulty = difficulty
	# get_tree().change_scene_to_file("res://scenes/mainscene.tscn")
