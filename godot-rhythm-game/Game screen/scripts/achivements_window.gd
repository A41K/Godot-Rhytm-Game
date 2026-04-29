extends Node2D

var is_dragging = false
var drag_offset = Vector2()

var window_size = Vector2(400, 300)
var top_bar_height = 30
var scroll_container: ScrollContainer

func _ready() -> void:
	var area = $Area2D
	if area:
		area.input_event.connect(_on_area_2d_input_event)

	_setup_achievements_ui()
	
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _setup_achievements_ui() -> void:
	var bg = Panel.new()
	bg.position = Vector2(0, top_bar_height)
	bg.size = Vector2(window_size.x, window_size.y - top_bar_height)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.2, 0.2)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	
	var title = Label.new()
	title.text = "A c h i e v e m e n t s"
	title.position = Vector2(0, top_bar_height + 8)
	title.size = Vector2(window_size.x, 25)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(title)

	
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(15, top_bar_height + 40)
	scroll_container.size = Vector2(window_size.x - 30, window_size.y - top_bar_height - 55)
	add_child(scroll_container)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll_container.add_child(vbox)

	
	var list = Global.achievements
	for key in list.keys():
		var data = list[key]
		
		var entry = PanelContainer.new()
		entry.custom_minimum_size = Vector2(0, 60)
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.18, 0.18, 0.20) if data["unlocked"] else Color(0.08, 0.08, 0.09)
		p_style.border_width_left = 4
		p_style.border_color = Color(1.0, 0.8, 0.2) if data["unlocked"] else Color(0.2, 0.2, 0.2)
		p_style.corner_radius_top_left = 3
		p_style.corner_radius_top_right = 3
		p_style.corner_radius_bottom_right = 3
		p_style.corner_radius_bottom_left = 3
		entry.add_theme_stylebox_override("panel", p_style)
		vbox.add_child(entry)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		var entry_margin = MarginContainer.new()
		entry_margin.add_theme_constant_override("margin_left", 10)
		entry_margin.add_theme_constant_override("margin_right", 10)
		entry_margin.add_child(hbox)
		entry.add_child(entry_margin)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(info_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = data["title"] + (" (Unlocked)" if data["unlocked"] else " (Locked)")
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 0.8) if data["unlocked"] else Color(0.6, 0.6, 0.6))
		info_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = data["description"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if data["unlocked"] else Color(0.4, 0.4, 0.4))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_vbox.add_child(desc_lbl)

func _draw() -> void:
	
	var bar_rect = Rect2(0, 0, window_size.x, top_bar_height)
	draw_rect(bar_rect, Color(0.18, 0.20, 0.22, 1.0)) 

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
		var new_pos = get_global_mouse_position() - drag_offset
		global_position.x = clamp(new_pos.x, 232, 1058 - window_size.x)
		global_position.y = clamp(new_pos.y, 62, 530 - window_size.y)

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
			
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(func(): get_parent().queue_free() if get_parent() and get_parent().name != "Applications + Background" else queue_free())
			return

		if local_pos.x >= 0 and local_pos.x <= window_size.x and local_pos.y >= 0 and local_pos.y <= top_bar_height:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
