extends Area2D
class_name RhythmNote

var type: int = 1 # 1=Up, 2=Left, 3=Down, 4=Right
var spawn_dir: String = "u"
var hit_time: float = 0.0
var target_pos: Vector2 = Vector2.ZERO
var speed: float = 300.0

var engine: RhythmEngine

@onready var sprite: Sprite2D = $Sprite2D

func setup(p_type: int, p_dir: String, p_hit_time: float, p_target: Vector2, p_speed: float, p_engine: RhythmEngine):
	type = p_type
	spawn_dir = p_dir
	hit_time = p_hit_time
	target_pos = p_target
	speed = p_speed
	engine = p_engine
	
	scale = Vector2(1.5, 1.5) 
	
	if sprite:
		var type_suffix = ""
		if Global.arrow_type == "circle":
			type_suffix = "circle"
		elif Global.arrow_type == "triangle":
			type_suffix = "triangle"
		elif Global.arrow_type == "star":
			type_suffix = "star"
		else: 
			type_suffix = "new"
			
		match type:
			1: 
				sprite.texture = load("res://assets/up" + type_suffix + ".png")
			2: 
				sprite.texture = load("res://assets/left" + type_suffix + ".png")
			3: 
				sprite.texture = load("res://assets/down" + type_suffix + ".png")
			4: 
				sprite.texture = load("res://assets/right" + type_suffix + ".png")
		

		sprite.scale = Vector2(0.28, 0.28)

	var dir_vector = Vector2.ZERO
	match spawn_dir:
		"u": dir_vector = Vector2(0, -1) 
		"d": dir_vector = Vector2(0, 1)  
		"l": dir_vector = Vector2(0, -1) 
		"r": dir_vector = Vector2(0, -1) 
		_: dir_vector = Vector2(0, -1)

	var current_time = engine.time_elapsed
	var time_left = hit_time - current_time
	position = target_pos + (dir_vector * (time_left * speed))

func _process(_delta: float):
	if not is_instance_valid(engine):
		return
		
	var current_time = engine.time_elapsed
	var time_left = hit_time - current_time
	
	if time_left < -0.3: 
		if is_instance_valid(engine):
			engine.add_miss()
		queue_free()
		return
		
	var dir_vector = Vector2.ZERO
	match spawn_dir:
		"u": dir_vector = Vector2(0, -1) 
		"d": dir_vector = Vector2(0, 1)  
		"l": dir_vector = Vector2(0, -1) 
		"r": dir_vector = Vector2(0, -1) 
		_: dir_vector = Vector2(0, -1)
		

	position = target_pos + (dir_vector * (time_left * speed))
