class_name LevelSelect
extends GameMenu



const LEVELS = [
	"res://levels/tutorial/tutorial.json",
	"res://levels/level2/level2.json",
	"res://levels/challenge1/challenge1.json",
]


func _ready() -> void:
	$Control/VBoxContainer/Song.grab_focus()


func _on_song_pressed(source: BaseButton) -> void:
	var idx = source.get_index()
	
	if idx >= 0 && idx < LEVELS.size():
		print("loading son")
		GameManager.start_level_sequence(LEVELS[idx])
