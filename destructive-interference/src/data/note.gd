class_name Note
extends RefCounted

var instrument: Instrument
var start_time: float
var band: int
var jumpable: bool
var pitch: float
var end_time: float

func _to_string() -> String:
	return "Note[Instrument=%s,StartTime=%.2f,Band=%d,Jumpable=%s,Pitch=%.2f]" % [instrument.instrument_name, start_time, band, jumpable, pitch]
