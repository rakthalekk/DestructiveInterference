extends GameMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control/PanelContainer/VBoxContainer/Retry.grab_focus()


func _on_retry_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.IN_GAME)


func _on_level_select_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.LEVEL_SELECT)


func _on_main_menu_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.MAIN_MENU)
