class_name LevelSelect
extends GameMenu



const LEVELS = [
	"res://levels/tutorial/tutorial.json",
	"res://levels/challenge1/challenge1.json",
	"res://levels/level2/level2.json",
	"res://levels/level3/level3.json"
]


var chosen_idx := 0


func _ready() -> void:
	_switch_to_main_select()


func _on_song_pressed(source: GameButton) -> void:
	var idx = source.get_index() - 1
	
	if idx >= 0 && idx < LEVELS.size():
		chosen_idx = idx
		_switch_to_choose_difficulty()


func _switch_to_choose_difficulty():
	%DifficultyScrollBox.visible = true
	%MainScrollBox.visible = false
	%EasyButton.grab_focus()
	%MainScrollBox.scroll_horizontal = 0
	%DifficultyScrollBox.scroll_horizontal = 0


func _switch_to_main_select():
	%MainScrollBox.visible = true
	%DifficultyScrollBox.visible = false
	%GameButton.grab_focus()
	%MainScrollBox.scroll_horizontal = 0
	%DifficultyScrollBox.scroll_horizontal = 0
	chosen_idx = 0


func _choose_difficulty(in_btn: GameButton) -> void:
	var diff = (in_btn.get_index() - 1) as LevelManager.DIFFICULTY
	print("loading son")
	GameManager.start_level_sequence(LEVELS[chosen_idx], diff)


func _on_back_pressed() -> void:
	GameManager.transition_to(GameManager.GAME_STATE.MAIN_MENU)


func _on_difficulty_back_button_pressed() -> void:
	_switch_to_main_select()
