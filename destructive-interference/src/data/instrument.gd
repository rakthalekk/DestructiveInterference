class_name Instrument
extends RefCounted

var instrument_name: String
var type: String
var color: Color
var goal: float

func _init(p_name: String, p_type: String, p_color: Color, p_goal: float) -> void:
	instrument_name = p_name
	type = p_type
	color = p_color
	goal = p_goal
