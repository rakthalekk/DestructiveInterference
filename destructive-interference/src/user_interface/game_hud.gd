class_name GameHUD
extends GameMenu


@onready var start_text := $StartText as Label


@onready var gain_meter := $PlayerHUD/GainMeter as ProgressBar

@onready var interfere_meters: Dictionary[ProgressBar, GameManager.WAVE_TYPE] = {
	%TriProg as ProgressBar: GameManager.WAVE_TYPE.TRIANGLE,
	%SqProg as ProgressBar: GameManager.WAVE_TYPE.SQUARE,
	%SawProg as ProgressBar: GameManager.WAVE_TYPE.SAW,
	%SinProg as ProgressBar: GameManager.WAVE_TYPE.SINE
}


func _process(_delta: float) -> void:
	gain_meter.value = PlayerManager.current_gain
	gain_meter.max_value = PlayerManager.MAX_GAIN
	
	for key: ProgressBar in interfere_meters.keys():
		if LevelManager.wave_goals.has(interfere_meters[key]):
			key.visible = true
			key.value = LevelManager.wave_interferences[interfere_meters[key]]
			key.max_value = LevelManager.wave_goals[interfere_meters[key]]
		else:
			key.visible = false
