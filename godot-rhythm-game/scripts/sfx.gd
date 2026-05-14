extends AudioStreamPlayer

func play_door_sound():
	var s = load("res://sounds/door.mp3")
	stream = s
	play()
