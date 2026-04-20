class_name Note
extends RefCounted

var instrument: Instrument
var start_time: float
var band_start: int
var band_end: int
var jumpable: bool
var pitch: float
var end_time: float
var is_first := false

# map of each band to an array of instrument names in the compound note
var compounds: Dictionary[int, Array]  = {}

func duplicate() -> Note:
	var new_note = Note.new()
	new_note.instrument = instrument
	new_note.start_time = start_time
	new_note.band_start = band_start
	new_note.band_end = band_end
	new_note.jumpable = jumpable
	new_note.pitch = pitch
	new_note.end_time = end_time
	new_note.is_first = is_first
	new_note.compounds = compounds.duplicate()
	return new_note
