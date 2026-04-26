extends Node2D

var is_dragging = false
var drag_offset = Vector2()

var window_size = Vector2(400, 300)
var top_bar_height = 30

func _ready() -> void:
	var area = $Area2D
	if area:
		area.input_event.connect(_on_area_2d_input_event)

	
	if has_node("Settings"):
		$Settings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Circle (ye reference)"):
		$"Circle (ye reference)".mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var body_rect = Rect2(0, top_bar_height, window_size.x, window_size.y - top_bar_height)
	draw_rect(body_rect, Color(0.1, 0.1, 0.1, 0.5)) 
	
	var bar_rect = Rect2(0, 0, window_size.x, top_bar_height)
	draw_rect(bar_rect, Color(0.8, 0.8, 0.8, 1.0)) 

	
	var radius = 6
	var y_center = top_bar_height / 2.0
	
	var right_edge = 15
	var x_red = right_edge
	var x_yellow = right_edge + 20
	var x_green = right_edge + 40
	
	draw_circle(Vector2(x_red, y_center), radius, Color(0.9, 0.3, 0.3))
	draw_circle(Vector2(x_yellow, y_center), radius, Color(1.0, 0.8, 0.2))
	draw_circle(Vector2(x_green, y_center), radius, Color(0.2, 0.8, 0.2))

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_pos = get_local_mouse_position()
		
		var x_red = 15
		var y_center = top_bar_height / 2.0
		
		
		if local_pos.distance_to(Vector2(x_red, y_center)) < 30: 
			if get_parent():
				get_parent().queue_free() 
			else:
				queue_free()
			return
		
		
		if local_pos.x >= 0 and local_pos.x <= window_size.x and local_pos.y >= 0 and local_pos.y <= top_bar_height:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position