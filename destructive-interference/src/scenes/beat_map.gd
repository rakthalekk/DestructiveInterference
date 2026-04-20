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

const PARTICLE = preload("res://src/entities/wave_particle.tscn")

##########################
##    BEATMAP STATES    ##
##########################

## Amount of lookahead, retrieved from songs & passed into beats to determine their speeds
var current_lookahead_time_seconds: float = 2.0

## List of lanes in order of index
var lanes: Array[Lane]

## Player 2D reference
@onready var player_2d := $Player2D as Player2D


func _ready() -> void:
	var lane_children = %LaneContainer.get_children()
	var lane_idx := 0
	for child in lane_children:
		lanes.push_back(child as Lane)
		(child as Lane).lane_idx = lane_idx
		lane_idx += 1

	player_2d.initialize_from_beatmap(self, 2, get_player_position_for_lane(2))

	LevelManager.create_subdivision_line.connect(_on_create_subdivision_line)


func _on_create_subdivision_line(width: float):
	var line = BEAT_LINE_SCENE.instantiate() as Line2D
	line.width = width
	$Lines.add_child(line)


func spawn_beat(note: Note):
	var beats_created: Array[Beat] = []
	for lane_idx in range(note.band_start, note.band_end + 1):
		if !is_valid_lane(lane_idx):
			push_warning("lane idx ", lane_idx, " out of bounds")
			return
	
		var beat := BEAT_SCENE.instantiate() as Beat
		beat.width = 1
		beat.note = note
		beat.i_makea_the_particle.connect(spawn_beat_particle)
		
		if lane_idx == note.band_start:
			beat.width = note.band_end - note.band_start + 1

		#var subd = LevelManager.subdivisions_per_beat
		#var bpm = LevelManager.bpm
		#var note_length = note.end_time - note.start_time


		lanes[lane_idx].add_beat(beat)
		#for i in range(note.band_start + 1, note.band_end + 1):
			#lanes[i].add_beat(beat, false) # inform these other lanes about the beat so they can render waveform squigglies, but don't add it a 2nd time
		beat.progress_ratio = 0.0
		beat.dispatch_beat(note, LevelManager.view_range, lane_idx)
		beats_created.append(beat)
	
	for beat in beats_created:
		for other_beat in beats_created:
			if beat != other_beat:
				beat.add_friend(other_beat)


func spawn_beat_particle(wave_type: GameManager.WAVE_TYPE):
	var particle: WaveParticle = PARTICLE.instantiate()
	particle.wave_type = wave_type
	$Player2D.add_child(particle)


func get_player_position_for_lane(in_lane_idx: int):
	return Vector2(lanes[in_lane_idx].position.x, PLAYER_Y)


func is_valid_lane(in_lane_idx: int):
	return in_lane_idx >= LANE_MIN && in_lane_idx <= LANE_MAX


func clear_notes_and_lines():
	for child in $Lines.get_children():
		child.queue_free()

	for lane in lanes:
		lane.beats = []
		for child in lane.get_children():
			child.queue_free()
