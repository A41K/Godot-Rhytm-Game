extends "res://Cutscenes/cutscene_logic.gd"

const LEFT_IMAGE := preload("res://assets/leftcircle.png")
const RIGHT_IMAGE := preload("res://assets/rightnew.png")
const NEXT_SCENE := preload("res://scenes/mainscene.tscn")


func _ready() -> void:
	if Global.played_first_cutscene:
		get_tree().change_scene_to_file("res://Game screen/scenes/hallway.tscn")
		return

	Global.played_first_cutscene = true
	Global.save_settings_to_disk()

	dialogue_script = """

image|res://images/1stday.jpg.##sound=res://sounds/thud.mp3

background|res://images/school.webp|0.5

left|You|Finally!!!!
left|You|I'm done with school for today.
left|You|This was really a pain in the ass.
left|You|I can finally go home, relax and play with my favourite game.

right|Jamie|Hey! What's up?
left|You|Hey Jamie! Everythings fine.
right|Jamie|Want me to walk home with you?
left|You|Yeah, honestly I really need some company.
right|Jamie|Well, lucky for you I caught you at the right time.
right|Jamie|But, it's not like we do this everyday...
left|You|Yeah, you have a point.

image|res://images/walkhome.jpg|0.5
background|res://images/infrontofhouse.webp

left|You|Well, thank you for the company. 
left|You|Like usual I had a great time.
right|Jamie|Honestly, it's nothing.
right|Jamie|I know everything is kinda bad right now.
right|Jamie|I just want to help you
left|You|Honestly, you're the best.
right|Jamie|Now get in before your mother bites my head off.
right|Jamie|Have a great night.
left|You|Yeah thanks, you too!!

image|res://images/blackscreen.jpg.##sound=res://sounds/door.mp3

"""

# image|res://images/OK.png|2
# left|Alice|Hey! You finally made it.
# left|
# right|What?

# right|Alex|Nice.##sound=res://sounds/Frontendbutton_up.wav



	next_scene = preload("res://Game screen/scenes/hallway.tscn")
	super._ready()
	_left_character.texture = LEFT_IMAGE
	_right_character.texture = RIGHT_IMAGE

	play_cutscene_from_script()
