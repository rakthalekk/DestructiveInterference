extends Node2D


const BEAT_TEST = preload("res://src/faye_test/beat_test.tscn")

@export_file_path var level_json


func _ready() -> void:
	LevelManager.load_data_from_json(level_json)
	LevelManager.start_level()
	
	LevelManager.warmup_finished.connect(hide_start_text)
	LevelManager.send_note.connect(_create_beat)


func hide_start_text():
	$StartText.hide()


func _create_beat(note: Note):
	var randx = randi_range(100, 1820)
	var beat = BEAT_TEST.instantiate() as BeatTest
	beat.load_data(note)
	beat.position = Vector2(randx, -32)
	add_child(beat)
