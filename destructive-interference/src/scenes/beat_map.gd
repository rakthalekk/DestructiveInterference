class_name BeatMap
extends Node2D


#########################
##   CLASS CONSTANTS   ##
#########################

const LANE_MIN = 0
const LANE_MAX = 4
const PLAYER_Y = 1000

## beat scene ref
const BEAT_SCENE = preload("res://src/entities/beat.tscn")


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


func spawn_beat(lane_idx: int):
	if !is_valid_lane(lane_idx):
		push_warning("lane idx ", lane_idx, " out of bounds")
		return
	
	var beat := BEAT_SCENE.instantiate() as Beat
	
	lanes[lane_idx].add_child(beat)
	beat.progress_ratio = 0.0


func get_player_position_for_lane(in_lane_idx: int):
	return Vector2(lanes[in_lane_idx].position.x, PLAYER_Y)


func is_valid_lane(in_lane_idx: int):
	return in_lane_idx >= LANE_MIN && in_lane_idx <= LANE_MAX


func _on_timer_timeout() -> void:
	spawn_beat([0, 1, 2, 3, 4].pick_random())
