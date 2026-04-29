extends Control

func _on_story_mode_button_pressed() -> void:
		Global.unlock_achievement("play_story")
		pass 

func _on_freeplay_button_pressed() -> void:
		Global.unlock_achievement("first_note")
		get_tree().change_scene_to_file("res://scenes/Freeplay.tscn")

func _on_quit_button_pressed() -> void:
		get_tree().change_scene_to_file("res://Game screen/scenes/computer.tscn")
