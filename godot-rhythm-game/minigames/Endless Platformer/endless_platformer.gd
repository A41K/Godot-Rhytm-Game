extends Node2D

const PlayerScript := preload("res://minigames/Endless Platformer/player.gd")

const WORLD_HALF_WIDTH := 310.0
const PLATFORM_MIN_SIZE := 64.0
const PLATFORM_START_SIZE := 122.0
const CAMERA_ABOVE_OFFSET := 92.0
const CAMERA_FALL_LIMIT := 470.0
const PLATFORM_FALL_DELAY := 0.35
const PLATFORM_VERTICAL_STEP_MIN := 68.0
const PLATFORM_VERTICAL_STEP_MAX := 98.0
const PLATFORM_HORIZONTAL_STEP_MIN := 82.0
const PLATFORM_HORIZONTAL_STEP_MAX := 138.0
const PLATFORM_SIDE_PADDING := 20.0

var rng := RandomNumberGenerator.new()
var world: Node2D
var platforms_root: Node2D
var camera: Camera2D
var player: EndlessPlatformerPlayer
var ui_layer: CanvasLayer
var score_label: Label
var hint_label: Label
var game_over_panel: ColorRect
var final_score_label: Label
var restart_label: Label

var score := 0
var game_over := false
var previous_platform: StaticBody2D
var target_platform: StaticBody2D
var active_platforms: Array[StaticBody2D] = []


func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_ui()
	_build_player()
	_reset_run()


func _process(_delta: float) -> void:
	if not player or game_over:
		if game_over and Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	if player.global_position.y < camera.global_position.y - CAMERA_ABOVE_OFFSET:
		camera.global_position.y = player.global_position.y - CAMERA_ABOVE_OFFSET

	camera.global_position.x = lerpf(camera.global_position.x, player.global_position.x, 0.08)

	if player.global_position.y > camera.global_position.y + CAMERA_FALL_LIMIT:
		_trigger_game_over()


func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	platforms_root = Node2D.new()
	platforms_root.name = "Platforms"
	world.add_child(platforms_root)

	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(1.0, 1.0)
	world.add_child(camera)
	camera.make_current()


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.06, 0.08, 0.12, 0.18)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(backdrop)

	var hud := Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(hud)

	score_label = Label.new()
	score_label.position = Vector2(24.0, 18.0)
	score_label.add_theme_font_size_override("font_size", 24)
	hud.add_child(score_label)

	hint_label = Label.new()
	hint_label.position = Vector2(24.0, 46.0)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.modulate = Color(0.85, 0.9, 1.0)
	hint_label.text = "A/D move   W jump   R restart"
	hud.add_child(hint_label)

	game_over_panel = ColorRect.new()
	game_over_panel.color = Color(0.0, 0.0, 0.0, 0.68)
	game_over_panel.visible = false
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(game_over_panel)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var game_over_label := Label.new()
	game_over_label.text = "Game Over"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 40)
	box.add_child(game_over_label)

	final_score_label = Label.new()
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score_label.add_theme_font_size_override("font_size", 22)
	box.add_child(final_score_label)

	restart_label = Label.new()
	restart_label.text = "Press R to retry"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.add_theme_font_size_override("font_size", 18)
	box.add_child(restart_label)


func _build_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1

	var visual := Polygon2D.new()
	visual.name = "Visual"
	player.add_child(visual)

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	player.add_child(collision_shape)

	world.add_child(player)
	player.landed_on_platform.connect(_on_player_landed_on_platform)
	player.fell_off.connect(_trigger_game_over)


func _reset_run() -> void:
	score = 0
	game_over = false
	final_score_label.text = ""
	game_over_panel.visible = false
	_clear_platforms()

	var start_platform := _create_platform(Vector2(0.0, 250.0), PLATFORM_START_SIZE, Color(0.72, 0.9, 1.0))
	previous_platform = start_platform
	player.reset_player(Vector2(0.0, start_platform.global_position.y - (PLATFORM_START_SIZE * 0.5) - 20.0))
	camera.global_position = player.global_position
	target_platform = _spawn_next_platform(previous_platform)
	_update_score_labels()


func _update_score_labels() -> void:
	score_label.text = "Score: %d" % score


func _clear_platforms() -> void:
	for platform in active_platforms:
		if is_instance_valid(platform):
			platform.queue_free()
	active_platforms.clear()
	previous_platform = null
	target_platform = null


func _create_platform(position: Vector2, size: float, color: Color) -> StaticBody2D:
	var platform := StaticBody2D.new()
	platform.position = position
	platform.collision_layer = 1
	platform.collision_mask = 0
	platform.set_meta("platform_size", size)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = color
	var half_size := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size),
	])
	platform.add_child(visual)

	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size, size)
	collision_shape.shape = shape
	platform.add_child(collision_shape)

	platforms_root.add_child(platform)
	active_platforms.append(platform)
	return platform
func _spawn_next_platform(source_platform: StaticBody2D) -> StaticBody2D:
	if not is_instance_valid(source_platform):
		return null

	var source_size := float(source_platform.get_meta("platform_size", PLATFORM_START_SIZE))
	var difficulty := float(score)
	var new_size: float = maxf(PLATFORM_MIN_SIZE, PLATFORM_START_SIZE - difficulty * 1.5)
	var move_direction: float = 1.0
	if is_instance_valid(player):
		move_direction = signf(player.facing_direction)
	if move_direction == 0.0:
		move_direction = 1.0 if score % 2 == 0 else -1.0

	var new_x_base: float = source_platform.global_position.x + (move_direction * rng.randf_range(PLATFORM_HORIZONTAL_STEP_MIN, PLATFORM_HORIZONTAL_STEP_MAX))
	var new_x: float = clampf(new_x_base, -WORLD_HALF_WIDTH + new_size * 0.5, WORLD_HALF_WIDTH - new_size * 0.5)
	var new_y: float = source_platform.global_position.y - (source_size * 0.5 + new_size * 0.5 + rng.randf_range(PLATFORM_VERTICAL_STEP_MIN, PLATFORM_VERTICAL_STEP_MAX))
	if new_y > player.global_position.y - 62.0:
		new_y = player.global_position.y - 62.0

	var tint_mix: float = clampf(difficulty / 18.0, 0.0, 1.0)
	var tint := Color(0.45, 0.72, 1.0).lerp(Color(1.0, 0.72, 0.45), tint_mix)
	return _create_platform(Vector2(new_x, new_y), new_size, tint)


func _on_player_landed_on_platform(platform: Node) -> void:
	if game_over:
		return
	if platform != target_platform:
		return

	score += 1
	_update_score_labels()

	if previous_platform and is_instance_valid(previous_platform):
		_fade_platform(previous_platform)

	previous_platform = target_platform
	target_platform = _spawn_next_platform(previous_platform)


func _fade_platform(platform: StaticBody2D) -> void:
	if not is_instance_valid(platform):
		return

	var visual := platform.get_node_or_null("Visual") as CanvasItem
	if visual == null:
		platform.queue_free()
		return

	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, PLATFORM_FALL_DELAY)
	tween.tween_callback(platform.queue_free)


func _trigger_game_over() -> void:
	if game_over:
		return

	game_over = true
	player.set_playing(false)
	final_score_label.text = "You climbed %d cubes." % score
	game_over_panel.visible = true
