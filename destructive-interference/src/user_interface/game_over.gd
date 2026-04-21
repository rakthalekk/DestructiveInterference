extends GameMenu



@onready var header := $Control/PanelContainer/Header as Label

@onready var bkgd := $Background as ColorRect


func _ready() -> void:
	if LevelManager.current_level_json_file == AudioManager.JSON_SONGS.keys()[3]:
		(%Enemy as WomanHole).set_bitch()
	else:
		%Enemy.set_police()
	
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
		$Control.position += Vector2.RIGHT * 250
		#$Control/PanelContainer.position += Vector2.RIGHT * 250
		#$Control/Panel.position += Vector2.RIGHT * 250
		%Woman.visible = true
		%Enemy.visible = false
		
		var woman_dialogue := [
			"Great Vibes!", 
			"Nice Tunes!", 
			"Good Job!", 
			"Wishlist Apocalypse Approaches on Steam",
			"My Vibes are Impeccable",
			"That's About It, See Ya."
		]
		
		woman_dialogue.shuffle()
		
		(%Woman as WomanHole).yap(woman_dialogue.pick_random())
	else:
		header.text = "defeat!"
		header.add_theme_color_override("font_color", red)
		bkgd.color = red
		$Control.position += Vector2.LEFT * 250
		#$Control/PanelContainer.position += Vector2.LEFT * 250
		#$Control/Panel.position += Vector2.LEFT * 250
		%Woman.visible = false
		%Enemy.visible = true
		
		var enemy_dialog := [
			"GET WRECKED!", 
			"I HATE MUSIC ! RAHHHH!!!", 
			"Heh, Nice try, looser", 
			"Wishlist Apocalypse Approaches on Steam!",
			"My Vibes are Impeccable.",
			"I'm So Sigma",
			"My disappointment is Mearueable and my Day is Saved"
		]
		enemy_dialog.shuffle()
		
		(%Enemy as WomanHole).yap(enemy_dialog.pick_random())


func _on_retry_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.IN_GAME)


func _on_level_select_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.LEVEL_SELECT)


func _on_main_menu_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.MAIN_MENU)
