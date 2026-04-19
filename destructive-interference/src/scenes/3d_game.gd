extends Node3D


@export_file_path var level_json


@onready var beatmap: BeatMap = %BeatMap


func _ready() -> void:
	LevelManager.load_data_from_json(level_json)
	LevelManager.start_level()
	
	LevelManager.warmup_finished.connect(hide_start_text)
	LevelManager.send_note.connect(_create_beat)
	
	beatmap.current_lookahead_time_seconds = LevelManager.view_range


func hide_start_text():
	GameManager.game_hud.start_text.hide()


func _create_beat(note: Note):
	beatmap.spawn_beat(note, GameManager.STRING_TO_WAVE_TYPE[note.instrument.type])
