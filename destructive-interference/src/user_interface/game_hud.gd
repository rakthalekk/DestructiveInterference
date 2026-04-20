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
	gain_meter.value = PlayerManager.current_gain
	gain_meter.max_value = PlayerManager.MAX_GAIN


func setup_hud():
	var idx = 0
	for key in LevelManager.wave_goals.keys():
		interfere_meters[idx].setup_goal_container(LevelManager.wave_goals[key], key)
		idx += 1
	
	for i in range(idx, interfere_meters.size()):
		interfere_meters[i].visible = false
