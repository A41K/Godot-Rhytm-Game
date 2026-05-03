class_name EndlessPlatformerPlayer
extends CharacterBody2D

signal landed_on_platform(platform: Node)
signal fell_off

const MOVE_SPEED := 280.0
const JUMP_VELOCITY := -800.0
const GRAVITY := 1400.0
const MAX_FALL_SPEED := 1400.0

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var playing := true
var was_on_floor := false
var facing_direction := 1.0


func _ready() -> void:
	visual.color = Color(0.96, 0.97, 1.0)
	visual.polygon = PackedVector2Array([
		Vector2(-14.0, -20.0),
		Vector2(14.0, -20.0),
		Vector2(14.0, 20.0),
		Vector2(-14.0, 20.0),
	])

	var shape := RectangleShape2D.new()
	shape.size = Vector2(28.0, 40.0)
	collision_shape.shape = shape


func reset_player(start_position: Vector2) -> void:
	playing = true
	was_on_floor = false
	velocity = Vector2.ZERO
	global_position = start_position


func set_playing(enabled: bool) -> void:
	playing = enabled
	if not enabled:
		velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not playing:
		return

	var move_input := Input.get_axis("left", "right")
	if move_input != 0.0:
		facing_direction = signf(move_input)
		velocity.x = move_toward(velocity.x, move_input * MOVE_SPEED, 2200.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 2400.0 * delta)

	if is_on_floor() and Input.is_action_just_pressed("up"):
		velocity.y = JUMP_VELOCITY
	elif not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	move_and_slide()

	if not was_on_floor and is_on_floor():
		var landed_platform: Node = null
		for collision_index in range(get_slide_collision_count()):
			var collision := get_slide_collision(collision_index)
			if collision.get_normal().dot(Vector2.UP) > 0.7:
				landed_platform = collision.get_collider()
				break
		landed_on_platform.emit(landed_platform)

	was_on_floor = is_on_floor()

	if global_position.y > 2600.0:
		fell_off.emit()
