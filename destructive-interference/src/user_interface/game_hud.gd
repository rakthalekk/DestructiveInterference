class_name GameHUD
extends CanvasLayer


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
	
	for key: ProgressBar in interfere_meters.keys():
		key.value = LevelManager.wave_tolerances[interfere_meters[key]]
