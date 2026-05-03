extends CanvasLayer

func _ready():
		process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_pressed():
		get_tree().paused = false
		queue_free()

func _on_options_pressed():
		var options = load("res://scenes/options_menu.tscn").instantiate()
		add_child(options)

func _on_quit_pressed():
		get_tree().paused = false
		queue_free()
		get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
