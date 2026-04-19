class_name Instrument
extends RefCounted

var instrument_name: String
var type: GameManager.WAVE_TYPE
var color: Color
var goal: float

func _init(p_name: String, p_type: String, p_color: Color, p_goal: float) -> void:
	instrument_name = p_name
	type = GameManager.STRING_TO_WAVE_TYPE[p_type]
	color = p_color
	goal = p_goal
