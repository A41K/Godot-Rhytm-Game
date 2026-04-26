extends Area2D

@onready var sprite = $Sprite2D 


func _ready() -> void:

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered() -> void:

	if sprite:

		if sprite.material:
			sprite.material.set_shader_parameter("line_thickness", 1.0)
		else:
			sprite.self_modulate = Color(1.5, 1.5, 1.5)
		

		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	if sprite:

		if sprite.material:
			sprite.material.set_shader_parameter("line_thickness", 0.0)
		else:
			sprite.self_modulate = Color(1, 1, 1)
		

		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Desk clicked! Transitioning to computer screen...")

		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		fade_and_transition("res://Game screen/scenes/computer.tscn")

func fade_and_transition(scene_path: String) -> void:
	var tree = get_tree()
	

	var transition_layer = CanvasLayer.new()
	transition_layer.layer = 100 
	

	var color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0) 
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	transition_layer.add_child(color_rect)
	

	tree.root.add_child(transition_layer)
	

	var tween = transition_layer.create_tween()
	tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), 0.5) 
	await tween.finished
	

	tree.change_scene_to_file(scene_path)
	

	var tween_out = transition_layer.create_tween()
	tween_out.tween_property(color_rect, "color", Color(0, 0, 0, 0), 0.5)
	tween_out.tween_callback(transition_layer.queue_free)
