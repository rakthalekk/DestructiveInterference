class_name MainMenu
extends GameMenu


var timer = 0.0

var stop := false

func _ready() -> void:
	_on_credits_back_pressed()


func _process(delta: float) -> void:
	if timer >= 1 && !stop:
		%WomanHole.yap("Let's save music!")
		stop = true
	
	timer += delta


func _on_start_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.LEVEL_SELECT)


func _on_options_pressed() -> void:
	%Main.visible = false
	%Options.visible = true
	%Credits.visible = false
	%OptionsBack.grab_focus()


func _on_credits_pressed() -> void:
	%Main.visible = false
	%Options.visible = false
	%Credits.visible = true
	%CreditsBack.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_options_back_pressed() -> void:
	%Main.visible = true
	%Options.visible = false
	%Credits.visible = false
	%Start.grab_focus()


func _on_credits_back_pressed() -> void:
	%Main.visible = true
	%Options.visible = false
	%Credits.visible = false
	%Start.grab_focus()
