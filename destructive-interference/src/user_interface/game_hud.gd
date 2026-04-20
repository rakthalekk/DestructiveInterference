class_name GameHUD
extends GameMenu


@onready var gain_meter := %GainMeter as TextureProgressBar


@onready var interfere_meters: Array[GoalContainerUI] = [
	%GoalContainer1 as GoalContainerUI,
	%GoalContainer2 as GoalContainerUI,
	%GoalContainer3 as GoalContainerUI,
	%GoalContainer4 as GoalContainerUI
]


func _process(_delta: float) -> void:
	var old_val = gain_meter.value
	gain_meter.value = PlayerManager.current_gain
	gain_meter.max_value = PlayerManager.MAX_GAIN
	gain_meter.value = clampf(gain_meter.value, 0, gain_meter.max_value)
	
	if old_val < gain_meter.value:
		$WomanHole/GainMeter/GainHit.stop()
		$WomanHole/GainMeter/GainHit.play("hit")


func setup_hud():
	var idx = 0
	for key in LevelManager.wave_goals.keys():
		interfere_meters[idx].setup_goal_container(LevelManager.wave_goals[key], key)
		idx += 1
	
	for i in range(idx, interfere_meters.size()):
		interfere_meters[i].visible = false
