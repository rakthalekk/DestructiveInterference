extends Node


enum WAVE_TYPE {
	NONE = -1,
	TRIANGLE,
	SQUARE,
	SAW,
	SINE,
	NOISE
}


const WAVE_TYPE_TO_STRING: Dictionary[WAVE_TYPE, String] = {
	WAVE_TYPE.NONE: "none",
	WAVE_TYPE.TRIANGLE: "triangle",
	WAVE_TYPE.SQUARE: "square",
	WAVE_TYPE.SAW: "saw",
	WAVE_TYPE.SINE: "sine",
	WAVE_TYPE.NOISE: "noise",
}


const STRING_TO_WAVE_TYPE: Dictionary[String, WAVE_TYPE] = {
	"none": WAVE_TYPE.NONE,
	"triangle": WAVE_TYPE.TRIANGLE,
	"square": WAVE_TYPE.SQUARE,
	"saw": WAVE_TYPE.SAW,
	"sine": WAVE_TYPE.SINE,
	"noise": WAVE_TYPE.NOISE,
}


@onready var game_hud := $GameHUD as GameHUD
