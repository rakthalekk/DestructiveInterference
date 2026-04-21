extends Node

signal warmup_finished
signal send_note(note: Note)
signal game_over(is_win: bool)
signal create_subdivision_line(width: float)

## y position of "current_time" in the song
const SCREEN_HEIGHT = 980


enum DIFFICULTY {
	EASY,
	MEDIUM,
	HARD,
	VERY_HARD
}

# NOTE: 0.25 indicates subdivision
var DIFFICULTY_BEAT_MODIFIERS_4: Dictionary[DIFFICULTY, float] = {
	DIFFICULTY.EASY: 1,
	DIFFICULTY.MEDIUM: 0.5,
	DIFFICULTY.HARD: 0.5,
	DIFFICULTY.VERY_HARD: 0.25,
}


var DIFFICULTY_BEAT_MODIFIERS_6: Dictionary[DIFFICULTY, float] = {
	DIFFICULTY.EASY: 1,
	DIFFICULTY.MEDIUM: 0.5,
	DIFFICULTY.HARD: 0.333333,
	DIFFICULTY.VERY_HARD: 0.1666667,
}


var DIFFICULTY_GOAL_TYPE_AMOUNTS: Dictionary[DIFFICULTY, int] = {
	DIFFICULTY.EASY: 2,
	DIFFICULTY.MEDIUM: 2,
	DIFFICULTY.HARD: 3,
	DIFFICULTY.VERY_HARD: 4,
}

var DIFFICULTY_GOAL_MODIFIERS: Dictionary[DIFFICULTY, float] = {
	DIFFICULTY.EASY: 0.5,
	DIFFICULTY.MEDIUM: 0.75,
	DIFFICULTY.HARD: 0.75,
	DIFFICULTY.VERY_HARD: 1,
}

var chosen_difficulty := DIFFICULTY.MEDIUM

var current_level_json_file: String

var level_title: String
var bpm: float = 120.0
var beats_per_measure: float = 4.0
var subdivisions_per_beat: float = 4.0
var duration_subdivision: float = 0.0
var duration_beat: float = 0.0
var view_range: float = 4.4
var view_range_beats: float = 4.0
var warmup_time: float = 6.0
var song_end: float = 15.0
var subdivision_offset := 0.0

var current_time: float = 0.0
var level_active: bool = false

var instruments: Dictionary[String, Instrument] = {}
var notes: Array[Note] = []
var next_note_idx = 0

var next_subdivision_idx := 0
var beat_num = 0

var warmup_timer = Timer.new()

var wave_goals: Dictionary[GameManager.WAVE_TYPE, float]
var wave_interferences: Dictionary[GameManager.WAVE_TYPE, float]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	warmup_timer.one_shot = true
	warmup_timer.timeout.connect(_on_warmup_timer_timeout)
	add_child(warmup_timer)

	GameManager.transitioned_game_state.connect(_on_state_transition)


func start_level(skip_warmup := false):
	level_active = true
	current_time = -view_range if skip_warmup else -warmup_time
	next_note_idx = 0
	next_subdivision_idx = 0

	warmup_timer.wait_time = view_range if skip_warmup else warmup_time
	warmup_timer.start()


func _on_warmup_timer_timeout():
	warmup_finished.emit()
	AudioManager.loop_level_song()


func load_data_from_json(level_json: String, in_difficulty := DIFFICULTY.MEDIUM):
	reset()
	
	chosen_difficulty = in_difficulty

	var beat_map: BeatMap = get_tree().get_first_node_in_group("beat_map") as BeatMap
	beat_map.clear_notes_and_lines()

	current_level_json_file = level_json

	var json_as_text = FileAccess.get_file_as_string(level_json)
	var level_data: Dictionary = JSON.parse_string(json_as_text)

	var metadata: Dictionary = level_data.metadata
	if metadata.has("title"):
		level_title = metadata.title

	bpm = metadata.bpm
	beats_per_measure = metadata.beats_per_measure
	subdivisions_per_beat = metadata.subdivisions_per_beat
	view_range = metadata.view_range
	view_range_beats = metadata.view_range_beats
	warmup_time = metadata.warmup_time
	song_end = metadata.song_end

	# why does it need to be divided by 2.............
	subdivision_offset = (60 / bpm / subdivisions_per_beat / 2)

	# computed fields
	duration_beat = (60 / bpm)
	duration_subdivision = duration_beat / subdivisions_per_beat

	var instrument_data: Array = metadata.instruments
	var idx = 0
	for data in instrument_data:
		var instrument = Instrument.new(data.name, data.type, Color(data.color), data.goal)
		instruments[data.name] = instrument
		
		if idx >= DIFFICULTY_GOAL_TYPE_AMOUNTS[chosen_difficulty] && level_title != "novatutorial":
			continue
		
		var type = instrument.type
		wave_goals[type] = instrument.goal * DIFFICULTY_GOAL_MODIFIERS[chosen_difficulty]
		wave_interferences[type] = 0
		
		idx += 1

	# create noise instrument
	var noise_instrument = Instrument.new("noise", "noise", Color.WHITE, 9999)
	instruments["noise"] = noise_instrument

	var notes_data: Array = level_data.notes
	for data in notes_data:
		var note = Note.new()
		note.instrument = instruments[data.name]
		note.start_time = data.start
		note.start_beat = data.start_beat
		note.jumpable = data.jumpable
		note.pitch = data.pitch
		if data.band is float:
			note.band_start = data.band
			note.band_end = data.band
		elif data.band is Dictionary:
			note.band_start = data.band.start
			note.band_end = data.band.end

		if data.end:
			note.end_time = data.end
		else:
			note.end_time = note.start_time
		
		if data.compounds && chosen_difficulty == DIFFICULTY.VERY_HARD:
			for lane in data.compounds.keys():
				note.compounds[int(lane)] = data.compounds[lane]
		elif data.compounds:
			continue # skip compounds if not very hard difficulty

		if notes.size() <= 0:
			note.is_first = true

		notes.append(note)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !level_active || !GameManager.can_move:
		return

	current_time += delta

	# draw horizontal lines for measures / beats / subdivisions
	# has enough time passed to draw another subdivision line?
	if current_time + view_range >= next_subdivision_idx * duration_subdivision:

		if next_subdivision_idx % int(beats_per_measure * subdivisions_per_beat) == 0:
			# at a measure line
			beat_num = 0
			create_subdivision_line.emit(20)
		elif next_subdivision_idx % int(subdivisions_per_beat) == 0:
			# at a beat line
			beat_num += 1
			create_subdivision_line.emit(10)
		else:
			# at a subdivision line
			create_subdivision_line.emit(4)
		next_subdivision_idx += 1

	# we all outta notes
	if next_note_idx == notes.size():
		#current_time += delta

		if current_time >= song_end - view_range:
			start_level(true)

		return

	var is_player_win = true
	for key in wave_interferences.keys():
		if wave_interferences[key] < wave_goals[key]:
			is_player_win = false
			break

	if is_player_win:
		win()
		return

	# Explanation for magic number below.
	# We're positioning $Zero at y=SCREEN_HEIGHT as "current_time",
	# and y=0 as "current_time + view_range".
	# i.e. We calculate a beat's speed (in px/sec) as SCREEN_HEIGHT(px) / view_range(s).
	# But, the Path2Ds start a bit *above* y=0.
	# So, the notes have a bit *more* than SCREEN_HEIGHT pixels to traverse
	# before reaching $Zero.
	# Solution: look 38 pixels ahead in the beatmap for spawning notes. It's dumb but it works.
	var current_note: Note = notes[next_note_idx]
	while current_time + ((38 + SCREEN_HEIGHT) / SCREEN_HEIGHT) * view_range >= current_note.start_time:
		_try_send_note(current_note)

		next_note_idx += 1
		if next_note_idx < notes.size():
			current_note = notes[next_note_idx]
		else:
			print("no more notes!")
			break


func add_tolerance(wave_type: GameManager.WAVE_TYPE, amount := 1.0):
	var previously_goal_met := is_equal_approx(wave_interferences[wave_type], wave_goals[wave_type])
	wave_interferences[wave_type] += amount
	wave_interferences[wave_type] = clamp(wave_interferences[wave_type], 0.0, wave_goals[wave_type])
	if !previously_goal_met and is_equal_approx(wave_interferences[wave_type], wave_goals[wave_type]):
		run_when_goal_met(wave_type)

func run_when_goal_met(wave_type: GameManager.WAVE_TYPE):
	var wave_type_str = GameManager.WAVE_TYPE_TO_STRING[wave_type]
	print("u got all the %s u need, good job!" % [wave_type_str])
	var sfx_for_wave_type_goal = AudioManager.SFX_GOAL[wave_type_str]
	AudioManager.sfx_one_shot(sfx_for_wave_type_goal, 2.0)

func win():
	level_active = false
	GameManager.transition_to(GameManager.GAME_STATE.GAME_OVER)
	game_over.emit(true)
	print("Win!!!!")
	AudioManager.sfx_one_shot(AudioManager.SFX_LEVEL_END_VICTORY, 1.0)


func lose():
	level_active = false
	game_over.emit(false)
	print("Lose :(")
	AudioManager.sfx_one_shot(AudioManager.SFX_LEVEL_END_DEFEAT, 1.0)


## Fully reset the current level to 0 progress and beginning of the map
func reset():
	notes.clear()
	wave_goals.clear()
	wave_interferences.clear()
	next_subdivision_idx = 0
	beat_num = 0
	next_note_idx = 0


func _on_state_transition(from: GameManager.GAME_STATE, to: GameManager.GAME_STATE):
	if from == GameManager.GAME_STATE.GAME_OVER && to == GameManager.GAME_STATE.IN_GAME:
		AudioManager.level_song_player.stop()
		load_data_from_json(current_level_json_file)
		start_level(false)


func _try_send_note(in_note: Note):
	if !wave_goals.has(in_note.instrument.type):
		return
	
	var beat_int = int(in_note.start_beat)
	#var beat_float = in_note.start_beat - float(beat_int)
	#
	#var mod_by = DIFFICULTY_BEAT_MODIFIERS_4[chosen_difficulty] if subdivisions_per_beat == 4 else DIFFICULTY_BEAT_MODIFIERS_6[chosen_difficulty]
	
	var is_4_ok = is_zero_approx(fmod(in_note.start_beat, DIFFICULTY_BEAT_MODIFIERS_4[chosen_difficulty]))
	var is_6_ok = is_zero_approx(fmod(in_note.start_beat, DIFFICULTY_BEAT_MODIFIERS_6[chosen_difficulty]))
	
	if chosen_difficulty != DIFFICULTY.VERY_HARD:
		if subdivisions_per_beat == 4 && !is_4_ok:
			return
		elif subdivisions_per_beat == 6 && !(is_4_ok || is_6_ok):
			return
	
	#if !is_zero_approx(beat_float) && beat_float / DIFFICULTY_BEAT_MODIFIERS[chosen_difficulty] < 1:
		#return 
	
	# Check if note is divisible & note before isn't?
	#
	# example: 1/4s only
	# should be: .25, .5, 1 ok
	# should not be .125 or .0625
	#
	# need to check if curr beat / disallowed beats >= 1 i think
	
	if wave_interferences[in_note.instrument.type] < wave_goals[in_note.instrument.type]:
		send_note.emit(in_note)
	# do not create a noise note where there would be a compound note
	elif in_note.compounds.size() == 0:
		var noise_note = in_note.duplicate()
		noise_note.instrument = instruments["noise"]
		send_note.emit(noise_note)
