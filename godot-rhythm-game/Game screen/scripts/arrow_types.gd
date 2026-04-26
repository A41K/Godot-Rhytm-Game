extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Global.arrow_type = self.name.to_lower()
	print("Arrow type changed to: ", Global.arrow_type)
