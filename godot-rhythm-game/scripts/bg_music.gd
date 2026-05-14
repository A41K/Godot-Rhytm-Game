extends AudioStreamPlayer

var allowed_scenes = ["Hallway", "Upstairs", "Room"]

func _ready():
	var audio_stream = load("res://sounds/bg.mp3")
	stream = audio_stream
	bus = "Master"

func _process(_delta: float) -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		if current_scene.name in allowed_scenes:
			if not playing:
				play()
		else:
			if playing:
				stop()
