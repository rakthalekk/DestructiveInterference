extends Node3D


@export_file_path var level_json


@onready var camera_blocker := $Camera3D/CameraBlocker as Sprite3D

@onready var beatmap: BeatMap = %BeatMap

@onready var transition_animations := $TransitionAnimations as AnimationPlayer


func _ready() -> void:
	#LevelManager.warmup_finished.connect(hide_start_text)
	LevelManager.send_note.connect(_create_beat)
	GameManager.transitioned_game_state.connect(_on_game_state_transition)
	
	beatmap.current_lookahead_time_seconds = LevelManager.view_range
	
	GameManager.transition_to(GameManager.GAME_STATE.MAIN_MENU)
	
	camera_blocker.modulate = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color.WHITE)


#func hide_start_text():
	#if GameManager.current_hud is GameHUD:
		#GameManager.current_hud.start_text.hide()


func _on_game_state_transition(from: GameManager.GAME_STATE, to: GameManager.GAME_STATE):
	if [GameManager.GAME_STATE.PAUSED, GameManager.GAME_STATE.GAME_OVER].has(from):
		if to == GameManager.GAME_STATE.IN_GAME:
			transition_animations.play("unpause")
		else:
			transition_animations.play("outro")
	elif from == GameManager.GAME_STATE.LEVEL_SELECT && to == GameManager.GAME_STATE.IN_GAME:
		transition_animations.play("intro")
	elif from == GameManager.GAME_STATE.IN_GAME:
		transition_animations.play("pause")


func _create_beat(note: Note):
	beatmap.spawn_beat(note)
