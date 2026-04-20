extends GameMenu



@onready var header := $Control/PanelContainer/Header as Label

@onready var bkgd := $Background as ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control/PanelContainer/VBoxContainer/Retry.grab_focus()
	
	var is_win = true
	
	for key in LevelManager.wave_goals.keys():
		if LevelManager.wave_interferences[key] < LevelManager.wave_goals[key]:
			is_win = false
	
	var red = GameManager.wave_colors[GameManager.WAVE_TYPE.TRIANGLE]
	var geen = GameManager.wave_colors[GameManager.WAVE_TYPE.SQUARE]
	
	if is_win:
		header.text = "victory!"
		header.add_theme_color_override("font_color", geen)
		bkgd.color = geen
	else:
		header.text = "defeat!"
		header.add_theme_color_override("font_color", red)
		bkgd.color = red


func _on_retry_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.IN_GAME)


func _on_level_select_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.LEVEL_SELECT)


func _on_main_menu_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.MAIN_MENU)
