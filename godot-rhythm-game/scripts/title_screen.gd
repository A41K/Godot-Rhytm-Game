extends Control

@onready var story_btn = $Panel/VBoxContainer/StoryModeButton
@onready var freeplay_btn = $Panel/VBoxContainer/MidButtons/FreeplayButton
@onready var extras_btn = $Panel/VBoxContainer/MidButtons/ExtrasButton
@onready var quit_btn = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	# Set up pop-in animation and hover connections
	var buttons = [story_btn, freeplay_btn, extras_btn, quit_btn]
	
	var delay = 0.0
	for btn in buttons:
		# Set pivot to center for scaling
		btn.pivot_offset = btn.size / 2.0
		
		# Initial scale zero for pop-in effect
		btn.scale = Vector2.ZERO
		var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(delay)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.4)
		delay += 0.1
		
		# Connect hover signals
		btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))

func _on_btn_hover(btn: Control, hovered: bool) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if hovered:
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
		# Optional: slight rotation for extra juice
		tween.parallel().tween_property(btn, "rotation_degrees", randf_range(-3, 3), 0.1)
	else:
		tween.tween_property(btn, "scale", Vector2.ONE, 0.1)
		tween.parallel().tween_property(btn, "rotation_degrees", 0.0, 0.1)

func _on_story_mode_button_pressed() -> void:
		Global.unlock_achievement("play_story")
		get_tree().change_scene_to_file("res://scenes/Storymode.tscn")
		pass 

func _on_freeplay_button_pressed() -> void:
		Global.unlock_achievement("first_note")
		get_tree().change_scene_to_file("res://scenes/Freeplay.tscn")

func _on_quit_button_pressed() -> void:
		get_tree().change_scene_to_file("res://Game screen/scenes/computer.tscn")
