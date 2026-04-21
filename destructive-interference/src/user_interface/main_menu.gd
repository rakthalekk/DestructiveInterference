class_name MainMenu
extends GameMenu


var timer = 0.0

var stop := false

func _ready() -> void:
	$Control/Start.grab_focus()


func _process(delta: float) -> void:
	if timer >= 1 && !stop:
		%WomanHole.yap("Let's save music!")
		stop = true
	
	timer += delta


func _on_start_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.LEVEL_SELECT)


func _on_options_pressed() -> void:
	print("open options!")


func _on_credits_pressed() -> void:
	print("open credits!")


func _on_quit_pressed() -> void:
	get_tree().quit()
