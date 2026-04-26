extends Area2D


@export var input_action: String = "up" 
@export var assigned_type: int = 1         

var overlapping_notes: Array[RhythmNote] = []
var base_scale: Vector2 = Vector2.ONE
var hit_timer: float = 0.0
var base_color: Color = Color(0.2, 0.6, 1.0) 
@onready var sprite = $Sprite2D

func _ready() -> void:
	if sprite:
		var type_suffix = ""
		if Global.arrow_type == "circle":
			type_suffix = "circle"
		elif Global.arrow_type == "triangle":
			type_suffix = ""
		else:
			type_suffix = "new"
		sprite.texture = load("res://assets/up" + type_suffix + ".png")
		base_scale = sprite.scale
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.8) 

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	if hit_timer > 0.0:
		hit_timer -= delta
		if sprite:
			sprite.modulate = base_color.lightened(0.5) 
			sprite.scale = base_scale * 1.1
	else:
		
		if Input.is_action_pressed(input_action):
			if sprite:
				sprite.scale = base_scale * 0.9
				sprite.modulate = base_color.darkened(0.2) 
		else:
			if sprite:
				sprite.scale = base_scale
				sprite.modulate = Color(0.3, 0.3, 0.3, 0.8)


	if Input.is_action_just_pressed(input_action):
		attempt_hit()

func attempt_hit() -> void:
	if overlapping_notes.is_empty():
	
		print("Ghost Tap! Type: ", assigned_type)
		return
	
	var engine = get_parent().get_node_or_null("Engine") 
	var note_to_hit = overlapping_notes.pop_front()
	
	if is_instance_valid(engine):
		
		var time_diff = abs(note_to_hit.hit_time - engine.time_elapsed)
		engine.add_hit(time_diff)
		if time_diff < 0.2:
			hit_timer = 0.15
			
	note_to_hit.queue_free()

func _on_area_entered(area: Area2D) -> void:

	if area is RhythmNote:

		if area.type == assigned_type: 
			overlapping_notes.append(area)

func _on_area_exited(area: Area2D) -> void:

	if area in overlapping_notes:
		overlapping_notes.erase(area)
		print("MISSED NOTE Type: ", assigned_type)
