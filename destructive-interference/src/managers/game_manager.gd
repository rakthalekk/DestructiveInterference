extends Node


signal transitioned_game_state(old_state: GAME_STATE, new_state: GAME_STATE)


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


var wave_colors: Dictionary[WAVE_TYPE, Color] = {
	WAVE_TYPE.TRIANGLE: Color("f66593"),
	WAVE_TYPE.SQUARE: Color("3efba3"),
	WAVE_TYPE.SAW: Color("77ffff"),
	WAVE_TYPE.SINE: Color("fff46d"),
	WAVE_TYPE.NOISE: Color("ffffff")
}


const STRING_TO_WAVE_TYPE: Dictionary[String, WAVE_TYPE] = {
	"none": WAVE_TYPE.NONE,
	"triangle": WAVE_TYPE.TRIANGLE,
	"square": WAVE_TYPE.SQUARE,
	"saw": WAVE_TYPE.SAW,
	"sine": WAVE_TYPE.SINE,
	"noise": WAVE_TYPE.NOISE,
}

## enum representing possible game states
enum GAME_STATE {
	STARTUP,
	MAIN_MENU,
	LEVEL_SELECT,
	PAUSED,
	IN_GAME,
	GAME_OVER
}

## List of UI transitions for game states
var GAME_STATE_TRANSITIONS: Dictionary[GAME_STATE, Array] = {
	GAME_STATE.STARTUP: [GAME_STATE.MAIN_MENU],
	GAME_STATE.MAIN_MENU: [GAME_STATE.LEVEL_SELECT, GAME_STATE.IN_GAME],
	GAME_STATE.LEVEL_SELECT: [GAME_STATE.IN_GAME, GAME_STATE.MAIN_MENU],
	GAME_STATE.PAUSED: [GAME_STATE.LEVEL_SELECT, GAME_STATE.MAIN_MENU, GAME_STATE.IN_GAME],
	GAME_STATE.IN_GAME: [GAME_STATE.PAUSED, GAME_STATE.GAME_OVER],
	GAME_STATE.GAME_OVER: [GAME_STATE.LEVEL_SELECT, GAME_STATE.MAIN_MENU, GAME_STATE.IN_GAME]
}

## Dictionary of UI scenes to instantiate per GAME_STATE type
var GAME_STATE_SCENES: Dictionary[GAME_STATE, PackedScene] = {
	GAME_STATE.MAIN_MENU: preload("res://src/user_interface/main_menu.tscn"),
	GAME_STATE.LEVEL_SELECT: preload("res://src/user_interface/level_select.tscn"),
	GAME_STATE.PAUSED: preload("res://src/user_interface/pause_menu.tscn"),
	GAME_STATE.IN_GAME: preload("res://src/user_interface/game_hud_real.tscn"),
	GAME_STATE.GAME_OVER: preload("res://src/user_interface/game_over.tscn"),
}


var current_game_state := GAME_STATE.STARTUP

var current_hud: GameMenu

var in_game_hud_cache: GameMenu


var can_move: bool:
	get():
		return current_game_state == GAME_STATE.IN_GAME


@onready var ui_canvas := $UICanvas as CanvasLayer



## Function for transitioning between game states
func transition_to(to_game_state: GAME_STATE):
	if current_game_state == to_game_state || !GAME_STATE_TRANSITIONS[current_game_state].has(to_game_state):
		return
	
	var old_game_state = current_game_state
	current_game_state = to_game_state
	
	if is_instance_valid(current_hud):
		current_hud.transition_out()
		await current_hud.transition_complete
	
	current_hud = GAME_STATE_SCENES[current_game_state].instantiate() # anim player should auto-play in-transition
	ui_canvas.add_child(current_hud)
	
	transitioned_game_state.emit(old_game_state, current_game_state)
	
	if [GAME_STATE.MAIN_MENU, GAME_STATE.LEVEL_SELECT].has(to_game_state):
		AudioManager.switch_to_menu_song()
	
	if current_hud is GameHUD:
		current_hud.setup_hud()


func start_level_sequence(in_level_file: String):
	LevelManager.load_data_from_json(in_level_file)
	transition_to(GAME_STATE.IN_GAME)
	LevelManager.start_level()
	AudioManager.fade_menu_song_out()
