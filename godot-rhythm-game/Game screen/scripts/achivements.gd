extends Area2D

var is_hovered = false
var is_selected = false
var is_pressed_down = false

func _ready() -> void:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
		is_hovered = true
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		queue_redraw()

func _on_mouse_exited() -> void:
		is_hovered = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		is_pressed_down = false
		queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
						is_pressed_down = true
						is_selected = true
						queue_redraw()
						if event.double_click:
								Input.set_default_cursor_shape(Input.CURSOR_ARROW) 
								_open_achievements()
				else:
						is_pressed_down = false
						queue_redraw()

func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if not is_hovered:
						is_selected = false
						queue_redraw()

func _draw() -> void:
		if is_selected or is_hovered:
				var fill_color = Color(0.2, 0.5, 0.9, 0.3) 
				if is_pressed_down:
						fill_color = Color(0.2, 0.5, 0.9, 0.6) 
				elif is_selected:
						fill_color = Color(0.2, 0.5, 0.9, 0.4) 

				var bg_rect = Rect2(Vector2(-35, -20), Vector2(70, 60))
				draw_rect(bg_rect, fill_color, true)
				draw_rect(bg_rect, Color(0.3, 0.6, 1.0, 0.6), false)

func _open_achievements() -> void:
		for child in get_parent().get_children():
				if child.name == "AchivementsWindowInstance":
						return 

		var achpv_scene = load("res://Game screen/scenes/achivements.tscn")
		if achpv_scene:
				var achpv_window = achpv_scene.instantiate()
				achpv_window.name = "AchivementsWindowInstance"
				get_parent().add_child(achpv_window)
				achpv_window.position = Vector2(0, 0)
		else:
				print("Failed to load achievements scene")
