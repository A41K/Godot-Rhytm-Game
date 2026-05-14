extends "res://Cutscenes/cutscene_logic.gd"

const LEFT_IMAGE := preload("res://assets/leftcircle.png")
const RIGHT_IMAGE := preload("res://assets/downtriangle.png")
const NEXT_SCENE := preload("res://scenes/mainscene.tscn")


func _ready() -> void:

	dialogue_script = """

left|You|*sighs* I think I had enough of games for today
left|You|*checks phone* She still didn't respond... weird
left|You|Ring Ring Ring.##sound=res://sounds/ring.mp3
left|You|Yeah?
right|???|Hey, What's up
left|Who am I talking to?
right|Connor|Connor, Y'know we go to the same class
left|You|Ahhh yeah I remember. What's up?
right|Connor|Call her. She isn't okay
left|You|What?
right|Connor|*hangs up
left|You|Damn... okay
left|You|*picks up phone and calls her



"""

# image|res://images/OK.png|2
# left|Alice|Hey! You finally made it.
# left|
# right|What?

# right|Alex|Nice.##sound=res://sounds/Frontendbutton_up.wav



	next_scene = preload("res://Cutscenes/day2/day2.1.tscn")
	super._ready()
	_left_character.texture = LEFT_IMAGE
	_right_character.texture = RIGHT_IMAGE

	play_cutscene_from_script()
