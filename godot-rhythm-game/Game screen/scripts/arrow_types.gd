extends Button

@export var click_sound: AudioStream = preload("res://sounds/Frontendbutton_up.wav")
@onready var audio_player := AudioStreamPlayer.new()	

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Global.arrow_type = self.name.to_lower()
	print("Arrow type changed to: ", Global.arrow_type)
	audio_player.stream = click_sound
	audio_player.play()
