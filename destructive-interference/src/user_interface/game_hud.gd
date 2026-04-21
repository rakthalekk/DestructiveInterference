class_name GameHUD
extends GameMenu


@onready var gain_meter := %GainMeter as TextureProgressBar

@onready var protag := $WomanHole as WomanHole

@onready var enemy := $WomanHole2 as WomanHole


@onready var interfere_meters: Array[GoalContainerUI] = [
	%GoalContainer1 as GoalContainerUI,
	%GoalContainer2 as GoalContainerUI,
	%GoalContainer3 as GoalContainerUI,
	%GoalContainer4 as GoalContainerUI
]



# I fell to the dark side....
var tutorial_dialogue: Array = [
	[0.0, "RAH!! I HATE MUSIC! I'M GONNA KILL\nMUSIC WITH MUSIC!!!", false],
	[2.0, "Hey You! I need your help. Let me teach you how to play!", true],
	[7.0, "In a second, the music police are gonna send some squares", true],
	[11.0, "To save Music, we need to neutralize them. Press [J] on the beat in lane 4!", true],
	[15.0, "Nice job! In the bottom right, the Green counter went down.", true],
	[19.0, "Once they hit zero, they're *White Noise*, which you have to dodge!", true],
	[23.0, "Press [Space] to Jump, and [A] or [D] to move lanes.", true],
	[30.0, "Good luck dealing with my TRIANGLES, Bet you can't even hit [H]!", false],
	[36.0, "To my right is my *Gain Meter*. If that ever peaks, I lose!", true],
	[38.0, "Are you ready to deal with TWO RHYTHMS?!", false],
	[42.0, "Sometimes there may be multiple beats. Pick a good lane and neutralize!", true],
	[50.0, "HAH! Bet you didn't see CHORDS coming. You gotta press BOTH buttons for those!", false],
	[55.0, "To win, fully neutralize all waves. Goals are in the bottom right", true],
	[60.0, "The right controls are below me if you need a reminder.", true],
	[65.0, "Good luck, my dude! Lets save music * together * !", true],
]

var tutorial_idx = 0

var tutorial_timer := 0.0


func _ready() -> void:
	if LevelManager.current_level_json_file == AudioManager.JSON_SONGS.keys()[3]:
		($WomanHole2 as WomanHole).set_bitch()
	else:
		$WomanHole2.set_police()


func _process(delta: float) -> void:
	var old_val = gain_meter.value
	gain_meter.value = PlayerManager.current_gain
	gain_meter.max_value = PlayerManager.MAX_GAIN
	gain_meter.value = clampf(gain_meter.value, 0, gain_meter.max_value)
	
	gain_meter.value = remap(gain_meter.value, 0, gain_meter.max_value, gain_meter.max_value * .12, gain_meter.max_value * .7)
	
	if old_val < gain_meter.value:
		$WomanHole/GainMeter/GainHit.stop()
		$WomanHole/GainMeter/GainHit.play("hit")
	
	if LevelManager.current_level_json_file == AudioManager.JSON_SONGS.keys()[0]:
		_do_tutorial_stuff(delta)


func setup_hud():
	var idx = 0
	for key in LevelManager.wave_goals.keys():
		interfere_meters[idx].setup_goal_container(LevelManager.wave_goals[key], key)
		idx += 1
	
	for i in range(idx, interfere_meters.size()):
		interfere_meters[i].visible = false



func send_dialogue(in_text: String, is_protag: bool):
	if is_protag:
		protag.yap(in_text)
	else:
		enemy.yap(in_text)


func _do_tutorial_stuff(delta: float):
	if tutorial_idx < tutorial_dialogue.size() && tutorial_timer > tutorial_dialogue[tutorial_idx][0]:
		send_dialogue(tutorial_dialogue[tutorial_idx][1], tutorial_dialogue[tutorial_idx][2])
		tutorial_idx += 1
	
	tutorial_timer += delta
