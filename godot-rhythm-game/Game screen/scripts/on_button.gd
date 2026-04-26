extends Node2D

@onready var apps_bg = $"../Applications + Background"
@onready var area = $Button

var is_on = false
var time = 0.0

func _ready() -> void:
	apps_bg.modulate = Color(1, 1, 1, 0)
	apps_bg.visible = false
	area.input_event.connect(_on_area_2d_input_event)

func _process(delta: float) -> void:
	if not is_on:
		time += delta * 5.0 
		queue_redraw()

func _draw() -> void:
	var color = Color(0, 1, 0) if is_on else Color(1, 0, 0, 0.5 + 0.5 * sin(time))
	draw_circle(area.position, 10, color)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_on:
			is_on = true
			queue_redraw()
			
			apps_bg.visible = true
			var tween = create_tween()
			tween.tween_property(apps_bg, "modulate:a", 1.0, 2.0)
