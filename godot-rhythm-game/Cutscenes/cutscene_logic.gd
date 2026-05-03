extends Node2D

class_name CutsceneLogic

signal cutscene_finished

enum SpeakerSide { NONE, LEFT, RIGHT }

@export var play_on_ready := false
@export_multiline var dialogue_script := ""
@export var dialogue_box_texture: Texture2D = preload("res://images/Dialoguebox.png")
@export var type_sound: AudioStream
@export var typing_speed := 40.0
@export var speaking_scale := Vector2(1.08, 1.08)
@export var idle_scale := Vector2(0.9, 0.9)
@export var speaking_tint := Color.WHITE
@export var idle_tint := Color(0.65, 0.65, 0.65, 1.0)
@export var left_character_position := Vector2(260.0, 360.0)
@export var right_character_position := Vector2(990.0, 360.0)
@export var speaker_name_offset := Vector2(36.0, 10.0)
@export var overlay_image_position := Vector2(625.0, 250.0)
@export var overlay_image_scale := Vector2(1.0, 1.0)
@export var overlay_image_fade_in := 0.25
@export var overlay_image_fade_out := 0.25
@export var background_texture: Texture2D
@export var next_scene: PackedScene

var cutscene_lines: Array[Dictionary] = []
var current_line_index := -1
var is_cutscene_active := false
var is_typing := false
var _skip_requested := false
var _advance_requested := false

var _left_character: Sprite2D
var _right_character: Sprite2D
var _dialogue_box: TextureRect
var _speaker_name_label: Label
var _dialogue_label: Label
var _overlay_image: TextureRect
var _background_image: TextureRect
var _type_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_scene_nodes()
	_set_dialogue_box_visible(false)
	if play_on_ready and dialogue_script.strip_edges() != "":
		play_cutscene_from_script()


func play_cutscene(lines: Array) -> void:
	if is_cutscene_active:
		return

	var parsed_lines: Array[Dictionary] = []
	for line in lines:
		if line is Dictionary:
			parsed_lines.append(_normalize_line(line))

	if parsed_lines.is_empty():
		return

	cutscene_lines = parsed_lines
	is_cutscene_active = true
	current_line_index = -1
	_set_dialogue_box_visible(true)
	await _run_cutscene()


func play_cutscene_from_script() -> void:
	play_cutscene(_parse_dialogue_script(dialogue_script))


func finish_cutscene() -> void:
	is_cutscene_active = false
	is_typing = false
	_skip_requested = false
	_advance_requested = false
	_set_dialogue_box_visible(false)
	emit_signal("cutscene_finished")
	if next_scene != null:
		get_tree().change_scene_to_packed(next_scene)


func _unhandled_input(event: InputEvent) -> void:
	if not is_cutscene_active:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_request_skip_or_advance()
	return

	if event.is_action_pressed("ui_accept"):
		_request_skip_or_advance()


func _ensure_scene_nodes() -> void:
	var viewport_size := get_viewport_rect().size

	var background_root := get_node_or_null("BackgroundUI") as CanvasLayer
	if background_root == null:
		background_root = CanvasLayer.new()
		background_root.name = "BackgroundUI"
		background_root.layer = -1
		add_child(background_root)

	_background_image = background_root.get_node_or_null("BackgroundImage") as TextureRect
	if _background_image == null:
		_background_image = TextureRect.new()
		_background_image.name = "BackgroundImage"
		background_root.add_child(_background_image)


	_background_image.position = Vector2.ZERO
	_background_image.size = viewport_size
	_background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_image.texture = background_texture
	_background_image.visible = true
	_background_image.modulate = Color(1.0, 1.0, 1.0, 1.0 if background_texture != null else 0.0)

	var characters_root := get_node_or_null("Characters") as Node2D
	if characters_root == null:
		characters_root = Node2D.new()
		characters_root.name = "Characters"
		add_child(characters_root)

	_left_character = _ensure_character_sprite(characters_root, "LeftCharacter", left_character_position)
	_right_character = _ensure_character_sprite(characters_root, "RightCharacter", right_character_position)

	var ui_root := get_node_or_null("UI") as CanvasLayer
	if ui_root == null:
		ui_root = CanvasLayer.new()
		ui_root.name = "UI"
		add_child(ui_root)

	var dialogue_root := ui_root.get_node_or_null("DialogueUI") as Control
	if dialogue_root == null:
		dialogue_root = Control.new()
		dialogue_root.name = "DialogueUI"
		dialogue_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		ui_root.add_child(dialogue_root)

	_dialogue_box = dialogue_root.get_node_or_null("DialogueBox") as TextureRect
	if _dialogue_box == null:
		_dialogue_box = TextureRect.new()
		_dialogue_box.name = "DialogueBox"
		dialogue_root.add_child(_dialogue_box)

	_dialogue_box.texture = dialogue_box_texture
	_dialogue_box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_box.stretch_mode = TextureRect.STRETCH_SCALE
	_dialogue_box.size = Vector2(900.0, 180.0)
	_dialogue_box.position = Vector2((viewport_size.x - _dialogue_box.size.x) * 0.5, viewport_size.y - _dialogue_box.size.y - 24.0)

	_speaker_name_label = _dialogue_box.get_node_or_null("SpeakerName") as Label
	if _speaker_name_label == null:
		_speaker_name_label = Label.new()
		_speaker_name_label.name = "SpeakerName"
		_dialogue_box.add_child(_speaker_name_label)

	_speaker_name_label.position = speaker_name_offset
	_speaker_name_label.size = Vector2(300.0, 32.0)
	_speaker_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_speaker_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_speaker_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speaker_name_label.text = ""

	_dialogue_label = _dialogue_box.get_node_or_null("DialogueText") as Label
	if _dialogue_label == null:
		_dialogue_label = Label.new()
		_dialogue_label.name = "DialogueText"
		_dialogue_box.add_child(_dialogue_label)

	_dialogue_label.position = Vector2(36.0, 52.0)
	_dialogue_label.size = Vector2(828.0, 88.0)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_dialogue_label.text = ""

	_overlay_image = ui_root.get_node_or_null("OverlayImage") as TextureRect
	if _overlay_image == null:
		_overlay_image = TextureRect.new()
		_overlay_image.name = "OverlayImage"
		ui_root.add_child(_overlay_image)

	_overlay_image.visible = false
	_overlay_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_overlay_image.position = overlay_image_position
	_overlay_image.scale = overlay_image_scale
	_overlay_image.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_type_player = get_node_or_null("TypeSound") as AudioStreamPlayer
	if _type_player == null:
		_type_player = AudioStreamPlayer.new()
		_type_player.name = "TypeSound"
		add_child(_type_player)

	_type_player.stream = type_sound

	_voice_player = get_node_or_null("VoicePlayer") as AudioStreamPlayer
	if _voice_player == null:
		_voice_player = AudioStreamPlayer.new()
		_voice_player.name = "VoicePlayer"
		_voice_player.stream = null
		add_child(_voice_player)

	_sfx_player = get_node_or_null("SFXPlayer") as AudioStreamPlayer
	if _sfx_player == null:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.name = "SFXPlayer"
		_sfx_player.stream = null
		add_child(_sfx_player)


func _ensure_character_sprite(parent: Node, node_name: String, position: Vector2) -> Sprite2D:
	var sprite := parent.get_node_or_null(node_name) as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = node_name
		parent.add_child(sprite)

	sprite.position = position
	sprite.centered = true
	sprite.scale = idle_scale
	sprite.modulate = idle_tint
	return sprite


func _run_cutscene() -> void:
	for index in range(cutscene_lines.size()):
		current_line_index = index
		await _play_cutscene_entry(cutscene_lines[index])

	finish_cutscene()


func _play_cutscene_entry(entry: Dictionary) -> void:
	var kind := str(entry.get("kind", "dialogue"))
	if kind == "background":
		await _show_background_image(entry)
		return
	if kind == "image":
		await _show_overlay_image(entry)
		return
	if kind == "sfx":
		_play_sound_once(entry.get("sound", null))
		return

	await _show_line(entry)


func _show_line(line: Dictionary) -> void:
	var speaker := int(line.get("speaker", SpeakerSide.NONE))
	var speaker_name := str(line.get("speaker_name", "")).strip_edges()
	var text := str(line.get("text", ""))
	var voice: Variant = line.get("voice", null)
	var sound: Variant = line.get("sound", null)
	var auto_advance := bool(line.get("auto_advance", false))
	var hold_time := float(line.get("hold_time", 0.0))

	_apply_speaker_state(speaker)
	_speaker_name_label.text = speaker_name
	_speaker_name_label.visible = not speaker_name.is_empty()
	_dialogue_label.text = ""
	is_typing = true
	_skip_requested = false
	_advance_requested = false
	_start_type_sound(text)
	_start_voice(voice)
	_play_sound_once(sound)

	if typing_speed <= 0.0:
		_dialogue_label.text = text
	else:
		var typed_text := ""
		for character in text:
			if _skip_requested:
				break

			typed_text += character
			_dialogue_label.text = typed_text

			await get_tree().create_timer(1.0 / typing_speed).timeout

		if _skip_requested:
			_dialogue_label.text = text

	is_typing = false
	_stop_type_sound()
	_stop_voice()

	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout
	elif auto_advance:
		await get_tree().create_timer(0.25).timeout
	else:
		await _wait_for_advance()


func _wait_for_advance() -> void:
	while is_cutscene_active and not _advance_requested:
		await get_tree().process_frame
	_advance_requested = false


func _request_skip_or_advance() -> void:
	if is_typing:
		_skip_requested = true
	else:
		_advance_requested = true


func _start_type_sound(text: String) -> void:
	if _type_player == null or _type_player.stream == null:
		return
	if text.strip_edges().is_empty():
		return

	_type_player.stop()
	_type_player.play()


func _stop_type_sound() -> void:
	if _type_player == null:
		return

	_type_player.stop()


func _start_voice(resource_path_or_stream: Variant) -> void:
	if resource_path_or_stream == null:
		return
	var stream: AudioStream = null
	if resource_path_or_stream is String:
		stream = load(str(resource_path_or_stream))
		if stream == null:
			printerr("CutsceneLogic: failed to load voice resource: " + str(resource_path_or_stream))
	elif resource_path_or_stream is AudioStream:
		stream = resource_path_or_stream
	if stream == null or _voice_player == null:
		return


	if _voice_player.stream == stream and _voice_player.playing:
		return

	_voice_player.stop()
	_voice_player.stream = stream

	var cls := ""
	if stream != null and typeof(stream) == TYPE_OBJECT:
		cls = stream.get_class()
	if cls == "AudioStreamSample" or cls == "AudioStreamWAV":
		
		stream.loop_mode = 1
	_voice_player.play()
	print("CutsceneLogic: voice started -> ", str(resource_path_or_stream))


func _stop_voice() -> void:
	if _voice_player == null:
		return
	if _voice_player.playing:
		_voice_player.stop()
		print("CutsceneLogic: voice stopped")


func _play_sound_once(resource_path_or_stream: Variant) -> void:
	if resource_path_or_stream == null or _sfx_player == null:
		return
	var stream: AudioStream = null
	if resource_path_or_stream is String:
		var path_str := str(resource_path_or_stream).strip_edges()
		path_str = _sanitize_resource_path(path_str)
		print("CutsceneLogic: attempting to load SFX -> ", path_str)
		stream = load(path_str)
		if stream == null:
			printerr("CutsceneLogic: failed to load sound resource: " + path_str)
	elif resource_path_or_stream is AudioStream:
		stream = resource_path_or_stream
	if stream == null:
		return

	_sfx_player.stop()
	_sfx_player.stream = stream

	var cls2 := ""
	if stream != null and typeof(stream) == TYPE_OBJECT:
		cls2 = stream.get_class()
	if cls2 == "AudioStreamSample" or cls2 == "AudioStreamWAV":
	
		stream.loop_mode = 0
	_sfx_player.play()
	print("CutsceneLogic: sfx played -> ", str(resource_path_or_stream))


func _sanitize_resource_path(path: String) -> String:
	var p := path.strip_edges()
	if p.begins_with("res:/") and not p.begins_with("res://"):
		p = p.replace("res:/", "res://")

	while p != "" and (p.ends_with(".") or p.ends_with(",") or p.ends_with("!") or p.ends_with("?") or p.ends_with(":") or p.ends_with(";") or p.ends_with(")")):
		p = p.substr(0, p.length() - 1).strip_edges()
	return p


func _show_overlay_image(entry: Dictionary) -> void:
	var texture: Variant = entry.get("texture")
	if texture == null:
		texture = entry.get("image")
	if texture == null:
		
		var maybe_sound: Variant = entry.get("sound", null)
		if maybe_sound != null:
			_play_sound_once(maybe_sound)
		await _hide_overlay_image(float(entry.get("fade_out", overlay_image_fade_out)))
		return
	if texture == null:
		return

	var hold_time := float(entry.get("hold_time", entry.get("duration", 0.75)))
	var fade_in_time := float(entry.get("fade_in", overlay_image_fade_in))
	var fade_out_time := float(entry.get("fade_out", overlay_image_fade_out))
	var position_value: Variant = entry.get("position", overlay_image_position)
	var scale_value: Variant = entry.get("scale", overlay_image_scale)

	var texture_rect := texture as Texture2D
	if texture_rect == null:
		return

	var path_text := str(entry.get("path", "")).to_lower()
	var cover_screen := bool(entry.get("cover", false)) or path_text.find("blackscreen") != -1 or path_text.find("walkhome") != -1 or path_text.find("school") != -1

	_overlay_image.texture = texture_rect
	if cover_screen:
		_overlay_image.position = Vector2.ZERO
		_overlay_image.size = get_viewport().get_visible_rect().size
		_overlay_image.scale = Vector2.ONE
		_overlay_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		
		var base_size := texture_rect.get_size()
		var viewport_size := get_viewport().get_visible_rect().size
		var target_width := viewport_size.x * 0.6
		if base_size.x < target_width * 0.9:
			var aspect := 1.0
			if base_size.x > 0:
				aspect = base_size.y / base_size.x
			base_size = Vector2(target_width, target_width * aspect)
		_overlay_image.size = base_size
		_overlay_image.position = _to_vector2(position_value, overlay_image_position)
		_overlay_image.scale = _to_vector2(scale_value, overlay_image_scale)
	_overlay_image.visible = true
	_overlay_image.modulate = Color(1.0, 1.0, 1.0, 0.0)

	
	var image_sound: Variant = entry.get("sound", null)
	if image_sound != null:
		_play_sound_once(image_sound)

	var fade_in_tween := create_tween()
	fade_in_tween.set_trans(Tween.TRANS_SINE)
	fade_in_tween.set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_property(_overlay_image, "modulate:a", 1.0, maxf(fade_in_time, 0.0))
	await fade_in_tween.finished

	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout

	var fade_out_tween := create_tween()
	fade_out_tween.set_trans(Tween.TRANS_SINE)
	fade_out_tween.set_ease(Tween.EASE_IN)
	fade_out_tween.tween_property(_overlay_image, "modulate:a", 0.0, maxf(fade_out_time, 0.0))
	await fade_out_tween.finished
	_overlay_image.visible = false


func _show_background_image(entry: Dictionary) -> void:
	var texture: Variant = entry.get("texture")
	if texture == null:
		texture = entry.get("image")
	if texture == null:
		return

	var texture_rect := texture as Texture2D
	if texture_rect == null:
		return

	var fade_in_time := float(entry.get("fade_in", overlay_image_fade_in))
	var fade_out_time := float(entry.get("fade_out", overlay_image_fade_out))

	if _background_image == null:
		return

	_background_image.texture = texture_rect
	_background_image.visible = true
	_background_image.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var fade_in_tween := create_tween()
	fade_in_tween.set_trans(Tween.TRANS_SINE)
	fade_in_tween.set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_property(_background_image, "modulate:a", 1.0, maxf(fade_in_time, 0.0))
	await fade_in_tween.finished


	await get_tree().process_frame


func _hide_overlay_image(fade_out_time: float) -> void:
	if _overlay_image == null or not _overlay_image.visible:
		return

	var fade_out_tween := create_tween()
	fade_out_tween.set_trans(Tween.TRANS_SINE)
	fade_out_tween.set_ease(Tween.EASE_IN)
	fade_out_tween.tween_property(_overlay_image, "modulate:a", 0.0, maxf(fade_out_time, 0.0))
	await fade_out_tween.finished
	_overlay_image.visible = false


func _to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is String:
		var parts := str(value).split(",")
		if parts.size() == 2:
			return Vector2(float(parts[0].strip_edges()), float(parts[1].strip_edges()))
	return fallback


func _apply_speaker_state(speaker: int) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	_tween_character_state(tween, _left_character, speaker == SpeakerSide.LEFT)
	_tween_character_state(tween, _right_character, speaker == SpeakerSide.RIGHT)


func _tween_character_state(tween: Tween, sprite: Sprite2D, speaking: bool) -> void:
	if sprite == null:
		return

	var target_scale := speaking_scale if speaking else idle_scale
	var target_tint := speaking_tint if speaking else idle_tint
	tween.parallel().tween_property(sprite, "scale", target_scale, 0.18)
	tween.parallel().tween_property(sprite, "modulate", target_tint, 0.18)


func _set_dialogue_box_visible(visible: bool) -> void:
	if _dialogue_box != null:
		_dialogue_box.visible = visible
	if _speaker_name_label != null:
		_speaker_name_label.visible = visible
	if _dialogue_label != null:
		_dialogue_label.visible = visible


func _normalize_line(line: Dictionary) -> Dictionary:
	var kind := str(line.get("kind", "dialogue"))
	if kind == "background":
		return {
			"kind": "background",
			"texture": line.get("texture", null),
			"path": str(line.get("path", "")),
			"fade_in": float(line.get("fade_in", overlay_image_fade_in)),
			"fade_out": float(line.get("fade_out", overlay_image_fade_out)),
		}
	if kind == "image":
		return {
			"kind": "image",
			"texture": line.get("texture", line.get("image", null)),
			"path": str(line.get("path", line.get("image_path", ""))),
			"hold_time": float(line.get("hold_time", line.get("duration", 0.75))),
			"fade_in": float(line.get("fade_in", overlay_image_fade_in)),
			"fade_out": float(line.get("fade_out", overlay_image_fade_out)),
			"position": line.get("position", overlay_image_position),
			"scale": line.get("scale", overlay_image_scale),
			"sound": line.get("sound", null),
			"cover": bool(line.get("cover", false)),
		}

	return {
		"kind": "dialogue",
		"speaker": _normalize_speaker(line.get("speaker", SpeakerSide.NONE)),
		"text": str(line.get("text", "")),
		"auto_advance": bool(line.get("auto_advance", false)),
		"hold_time": float(line.get("hold_time", 0.0)),
		"speaker_name": str(line.get("speaker_name", line.get("name", ""))),
		"voice": line.get("voice", line.get("v", null)),
		"sound": line.get("sound", line.get("s", null)),
	}


func _normalize_speaker(value: Variant) -> int:
	match value:
		
		SpeakerSide.LEFT, "left", "Left", "l", "L", 1:
			return SpeakerSide.LEFT
		SpeakerSide.RIGHT, "right", "Right", "r", "R", 2:
			return SpeakerSide.RIGHT
		_:
			return SpeakerSide.NONE


func _parse_dialogue_script(script_text: String) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for raw_line in script_text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		if line.begins_with("image|") or line.begins_with("show_image|"):
			var img_entry := _parse_image_command(line)
			
			lines.append(img_entry)
			continue

		if line.begins_with("background|") or line.begins_with("bg|"):
			lines.append(_parse_background_command(line))
			continue

		if line.begins_with("clear_image"):
			lines.append({"kind": "image", "texture": null, "hold_time": 0.0, "fade_in": 0.0, "fade_out": overlay_image_fade_out})
			continue

		var separator := line.find("|")
		if separator == -1:
			separator = line.find(":")

		var speaker_text := "none"
		var speaker_name := ""
		var dialogue_text := line
		if separator != -1:
			var parts := line.split("|")
			if parts.size() >= 3:
				speaker_text = parts[0].strip_edges()
				speaker_name = parts[1].strip_edges()
				dialogue_text = parts[2].strip_edges()
			elif parts.size() == 2:
				speaker_text = parts[0].strip_edges()
				dialogue_text = parts[1].strip_edges()
				speaker_name = _default_speaker_name(speaker_text)

		var voice_tag: Variant = null
		var sound_tag: Variant = null
		var tag_idx := dialogue_text.find("##")
		if tag_idx != -1:
			var tag_text := dialogue_text.substr(tag_idx + 2, dialogue_text.length() - tag_idx - 2).strip_edges()
			dialogue_text = dialogue_text.substr(0, tag_idx).strip_edges()
			for pair in tag_text.split("&"):
				var kv := pair.split("=")
				if kv.size() == 2:
					var k := kv[0].strip_edges().to_lower()
					var v := kv[1].strip_edges()
					if k == "voice":
						voice_tag = v
					elif k == "sound":
						sound_tag = v

		lines.append({
			"kind": "dialogue",
			"speaker": _normalize_speaker(speaker_text),
			"speaker_name": speaker_name,
			"text": dialogue_text,
			"voice": voice_tag,
			"sound": sound_tag,
		})

	return lines


func _parse_image_command(line: String) -> Dictionary:
	var parts := line.split("|")
	var sound_value: Variant = null
	var texture_path := ""
	var hold_time := 0.75
	var fade_in_time := overlay_image_fade_in
	var fade_out_time := overlay_image_fade_out
	var position_value: Variant = overlay_image_position
	var scale_value: Variant = overlay_image_scale

	if parts.size() >= 2:
		texture_path = parts[1].strip_edges()

		var inline_idx := texture_path.find("##")
		if inline_idx != -1:
			var inline_tags := texture_path.substr(inline_idx + 2, texture_path.length() - inline_idx - 2).strip_edges()
			texture_path = texture_path.substr(0, inline_idx).strip_edges()
			
			if texture_path.begins_with("res:/") and not texture_path.begins_with("res://"):
				texture_path = texture_path.replace("res:/", "res://")

			while texture_path != "" and (texture_path.ends_with(".") or texture_path.ends_with(",") or texture_path.ends_with("!") or texture_path.ends_with("?") or texture_path.ends_with(":") or texture_path.ends_with(";")):
				texture_path = texture_path.substr(0, texture_path.length() - 1).strip_edges()
			for pair in inline_tags.split("&"):
				var kv := pair.split("=")
				if kv.size() == 2:
					var k := kv[0].strip_edges().to_lower()
					var v := kv[1].strip_edges()
					if k == "sound":
						sound_value = v

	if parts.size() >= 3 and not parts[2].strip_edges().is_empty():
		hold_time = _safe_float(parts[2].strip_edges(), hold_time)
	if parts.size() >= 4 and not parts[3].strip_edges().is_empty():
		position_value = parts[3].strip_edges()
	if parts.size() >= 5 and not parts[4].strip_edges().is_empty():
		scale_value = parts[4].strip_edges()
	if parts.size() >= 6 and not parts[5].strip_edges().is_empty():
		fade_in_time = _safe_float(parts[5].strip_edges(), fade_in_time)
	if parts.size() >= 7 and not parts[6].strip_edges().is_empty():
		fade_out_time = _safe_float(parts[6].strip_edges(), fade_out_time)

	var texture := load(texture_path)

	if parts.size() >= 8 and not parts[7].strip_edges().is_empty():
		sound_value = parts[7].strip_edges()
	return {
		"kind": "image",
		"path": texture_path,
		"texture": texture,
		"hold_time": hold_time,
		"fade_in": fade_in_time,
		"fade_out": fade_out_time,
		"position": position_value,
		"scale": scale_value,
		"sound": sound_value,
		"cover": texture_path.to_lower().find("blackscreen") != -1,
	}


func _parse_background_command(line: String) -> Dictionary:
	var parts := line.split("|")
	var texture_path := ""
	var fade_in_time := overlay_image_fade_in
	var fade_out_time := overlay_image_fade_out

	if parts.size() >= 2:
		texture_path = _sanitize_resource_path(parts[1].strip_edges())
	if parts.size() >= 3 and not parts[2].strip_edges().is_empty():
		fade_in_time = _safe_float(parts[2].strip_edges(), fade_in_time)
	if parts.size() >= 4 and not parts[3].strip_edges().is_empty():
		fade_out_time = _safe_float(parts[3].strip_edges(), fade_out_time)

	return {
		"kind": "background",
		"path": texture_path,
		"texture": load(texture_path),
		"fade_in": fade_in_time,
		"fade_out": fade_out_time,
	}


func _safe_float(value: String, fallback: float) -> float:
	if value.is_valid_float():
		return value.to_float()
	return fallback


func _default_speaker_name(speaker_text: String) -> String:
	match speaker_text.to_lower():
		"left":
			return "Left"
		"right":
			return "Right"
		_:
			return speaker_text.capitalize()
