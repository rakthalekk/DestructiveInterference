extends Node

signal warmup_finished
signal send_note(note: Note)
signal create_subdivision_line(width: float)

var level_title: String
var bpm: float = 120.0
var beats_per_measure: float = 4.0
var subdivisions_per_beat: float = 4.0
var view_range: float = 4.4
var warmup_time: float = 6.0

var current_time: float = 0.0
var level_active: bool = false

var instruments: Dictionary[String, Instrument] = {}
var notes: Array[Note] = []
var current_note_idx = 0

var time_to_next_beat = 0.0
var subdivision_num = 1
var beat_num = 1

var warmup_timer = Timer.new()

@onready var wave_tolerances: Dictionary[GameManager.WAVE_TYPE, float] = {
	GameManager.WAVE_TYPE.TRIANGLE: 0.0,
	GameManager.WAVE_TYPE.SQUARE: 0.0,
	GameManager.WAVE_TYPE.SAW: 0.0,
	GameManager.WAVE_TYPE.SINE: 0.0,
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	warmup_timer.one_shot = true
	warmup_timer.timeout.connect(_on_warmup_timer_timeout)
	add_child(warmup_timer)


func start_level():
	level_active = true
	current_time = -warmup_time
	current_note_idx = 0
	time_to_next_beat = 60.0 / bpm / subdivisions_per_beat
	
	warmup_timer.wait_time = warmup_time
	warmup_timer.start()


func _on_warmup_timer_timeout():
	warmup_finished.emit()


func load_data_from_json(level_json: String):
	var json_as_text = FileAccess.get_file_as_string(level_json)
	var level_data: Dictionary = JSON.parse_string(json_as_text)
	
	var metadata: Dictionary = level_data.metadata
	if metadata.has("title"):
		level_title = metadata.title
	
	bpm = metadata.bpm
	beats_per_measure = metadata.beats_per_measure
	subdivisions_per_beat = metadata.subdivisions_per_beat
	view_range = metadata.view_range
	warmup_time = metadata.warmup_time
	
	var instrument_data: Array = metadata.instruments
	for data in instrument_data:
		var instrument = Instrument.new(data.name, data.type, Color(data.color), data.goal)
		instruments[data.name] = instrument
	
	var notes_data: Array = level_data.notes
	for data in notes_data:
		var note = Note.new()
		note.instrument = instruments[data.name]
		note.start_time = data.start
		note.jumpable = data.jumpable
		note.pitch = data.pitch
		if data.band is float:
			note.band_start = data.band
			note.band_end = data.band
		elif data.band is Dictionary:
			note.band_start = data.band.start
			note.band_end = data.band.end
		notes.append(note)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !level_active:
		return
	
	# first beat line should be for timestamp 0
	if current_time + view_range >= 0:
		if time_to_next_beat <= 0:
			# at a beat line
			if subdivision_num == subdivisions_per_beat:
				# at a measure linea
				if beat_num == beats_per_measure:
					beat_num = 1
					subdivision_num = 1
					create_subdivision_line.emit(20)
				else:
					subdivision_num = 1
					beat_num += 1
					create_subdivision_line.emit(10)
			else:
				create_subdivision_line.emit(4)
				subdivision_num += 1
			
			time_to_next_beat += 60.0 / bpm / subdivisions_per_beat
		
		time_to_next_beat -= delta
	
	# we all outta notes
	if current_note_idx == notes.size():
		current_time += delta
		return
	
	var current_note = notes[current_note_idx]
	while current_time >= current_note.start_time - view_range:
		send_note.emit(current_note)
		current_note_idx += 1
		if current_note_idx < notes.size():
			current_note = notes[current_note_idx]
		else:
			print("no more notes!")
			break
	
	current_time += delta


func add_tolerance(wave_type: GameManager.WAVE_TYPE, amount := 10.0):
	wave_tolerances[wave_type] += amount
