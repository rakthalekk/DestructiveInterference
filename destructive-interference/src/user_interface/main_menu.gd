class_name MainMenu
extends GameMenu



func _ready() -> void:
	$Control/VBoxContainer/Start.grab_focus()


func _on_start_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.LEVEL_SELECT)


func _on_options_pressed() -> void:
	print("open options!")


func _on_credits_pressed() -> void:
	print("open credits!")


func _on_quit_pressed() -> void:
	get_tree().quit()
