class_name PauseMenu
extends GameMenu


func _ready() -> void:
	$Control/PanelContainer/VBoxContainer/Resume.grab_focus()


func _on_resume_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.IN_GAME)


func _on_level_select_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.LEVEL_SELECT)


func _on_main_menu_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.MAIN_MENU)
