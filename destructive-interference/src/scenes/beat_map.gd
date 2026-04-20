class_name BeatMap
extends Node2D


#########################
##   CLASS CONSTANTS   ##
#########################

const LANE_MIN = 0
const LANE_MAX = 4
const PLAYER_Y = 940

## beat scene ref
const BEAT_SCENE = preload("res://src/entities/beat.tscn")

const BEAT_LINE_SCENE = preload("res://src/entities/beat_line.tscn")


##########################
##    BEATMAP STATES    ##
##########################

## Amount of lookahead, retrieved from songs & passed into beats to determine their speeds
var current_lookahead_time_seconds: float = 2.0

## List of lanes in order of index
var lanes: Array[Path2D]

## Player 2D reference
@onready var player_2d := $Player2D as Player2D


func _ready() -> void:
	var lane_children = %LaneContainer.get_children()
	for child in lane_children:
		lanes.push_back(child as Path2D)
	
	player_2d.initialize_from_beatmap(self, 2, get_player_position_for_lane(2))
	
	LevelManager.create_subdivision_line.connect(_on_create_subdivision_line)


func _on_create_subdivision_line(width: float):
	var line = BEAT_LINE_SCENE.instantiate() as Line2D
	line.width = width
	$Lines.add_child(line)


func spawn_beat(note: Note):
	var lane_idx = note.band_start
	var beat_width = note.band_end - note.band_start + 1
	
	if !is_valid_lane(lane_idx):
		push_warning("lane idx ", lane_idx, " out of bounds")
		return
	
	var beat := BEAT_SCENE.instantiate() as Beat
	beat.width = beat_width
	
	#var subd = LevelManager.subdivisions_per_beat
	#var bpm = LevelManager.bpm 
	#var note_length = note.end_time - note.start_time
	
	
	lanes[lane_idx].add_child(beat)
	beat.progress_ratio = 0.0
	beat.dispatch_beat(note, LevelManager.view_range)


func get_player_position_for_lane(in_lane_idx: int):
	return Vector2(lanes[in_lane_idx].position.x, PLAYER_Y)


func is_valid_lane(in_lane_idx: int):
	return in_lane_idx >= LANE_MIN && in_lane_idx <= LANE_MAX


func clear_notes_and_lines():
	for child in $Lines.get_children():
		child.queue_free()
	
	for lane in lanes:
		for child in lane.get_children():
			child.queue_free()
