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
				_start_game()
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

func _start_game() -> void:
	
	var animated_sprite = AnimatedSprite2D.new()
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("loading")
	sprite_frames.set_animation_speed("loading", 10.0) 
	sprite_frames.set_animation_loop("loading", false) 
	
	for i in range(30):
		var frame_index = str(i).pad_zeros(2)
		var path = "res://Game screen/assets/loading gif images/frame_%s_delay-0.1s.png" % frame_index
		var img = Image.load_from_file(path)
		if img:
			var texture = ImageTexture.create_from_image(img)
			sprite_frames.add_frame("loading", texture)
		else:
			print("Failed to load: ", path)
			
	animated_sprite.sprite_frames = sprite_frames
	
	
	var monitor_bg = get_parent().get_node("Monitorbackground")
	if monitor_bg and sprite_frames.get_frame_count("loading") > 0:
		animated_sprite.position = monitor_bg.position
		var target_size = monitor_bg.texture.get_size() * monitor_bg.scale
		var source_size = sprite_frames.get_frame_texture("loading", 0).get_size()
		animated_sprite.scale = target_size / source_size
	else:
		animated_sprite.position = Vector2(645, 295)
		
	get_parent().add_child(animated_sprite)
	animated_sprite.play("loading")
	

	get_parent().get_node("Monitorbackground").visible = false
	self.visible = false
	

	await animated_sprite.animation_finished
	
	
	var title_screen_scene = load("res://scenes/TitleScreen.tscn")
	if title_screen_scene:
		get_tree().change_scene_to_packed(title_screen_scene)
	else:
		print("TitleScreen node/scene not found, skipping transition.")
