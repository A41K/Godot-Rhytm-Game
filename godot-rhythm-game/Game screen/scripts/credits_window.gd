extends Node2D

var is_dragging = false
var drag_offset = Vector2()

var window_size = Vector2(400, 300)
var top_bar_height = 30

@onready var master_slider = $Volumes/MasterSlider
@onready var music_slider = $Volumes/MusicSlider
@onready var sfx_slider = $Volumes/SFXSlider

func _ready() -> void:
		var area = $Area2D
		if area:
				area.input_event.connect(_on_area_2d_input_event)

		if has_node("Settings"):
				$Settings.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if has_node("Circle (ye reference)"):
				$"Circle (ye reference)".mouse_filter = Control.MOUSE_FILTER_IGNORE

		_setup_options_ui()
		_setup_volume_sliders()

		scale = Vector2.ZERO
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _setup_volume_sliders():
		if master_slider:
				master_slider.value = Global.master_volume
				master_slider.value_changed.connect(func(v): Global.master_volume = v; Global.apply_volumes())
		if music_slider:
				music_slider.value = Global.music_volume
				music_slider.value_changed.connect(func(v): Global.music_volume = v; Global.apply_volumes())
		if sfx_slider:
				sfx_slider.value = Global.sfx_volume
				sfx_slider.value_changed.connect(func(v): Global.sfx_volume = v; Global.apply_volumes())

func _setup_options_ui() -> void:
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
		move_child(bg, 0)

		if has_node("Settings/Label"):
				$Settings/Label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		if has_node("Circle (ye reference)/Label"):
				$"Circle (ye reference)/Label".add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

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
						if Global:
								Global.save_settings_to_disk()
						var tween = create_tween()
						tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
						tween.tween_callback(func(): get_parent().queue_free() if get_parent() and get_parent().name != "Applications + Background" else queue_free())
						return

				if local_pos.x >= 0 and local_pos.x <= window_size.x and local_pos.y >= 0 and local_pos.y <= top_bar_height:
						is_dragging = true
						drag_offset = get_global_mouse_position() - global_position
