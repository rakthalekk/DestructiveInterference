extends Control

var midi_data: MidiData = preload("res://assets/midis/example2.mid")


func _ready() -> void:
	_play()


func _play():
	var initial_delay := midi_data.tracks[0].get_offset_in_seconds()
	match midi_data.header.format:
		MidiData.Header.Format.SINGLE_TRACK, MidiData.Header.Format.MULTI_SONG:
			var us_per_beat: int = 500_000
			for event in midi_data.tracks[0].events:
				initial_delay += midi_data.header.convert_to_seconds(us_per_beat, event.delta_time)
				var tempo := event as MidiData.Tempo
				var note_on := event as MidiData.NoteOn
				if tempo != null:
					us_per_beat = tempo.us_per_beat
				elif note_on != null:
					# TODO: wait for initial_delay and play note_on.note
					if initial_delay > 0:
						await get_tree().create_timer(initial_delay).timeout
					
					$Note.text = note_on.note_name
					initial_delay = 0
		MidiData.Header.Format.MULTI_TRACK:
			var index = 0
			var tempo_map: Array[Vector2i] = midi_data.tracks[0].get_tempo_map()
			
			var us_per_beat := tempo_map[index].y
			var time: int = 0
			for event in midi_data.tracks[1].events:
				time += event.delta_time
				while index < tempo_map.size() - 1 && time >= tempo_map[index].x:
					index += 1
					us_per_beat = tempo_map[index].y
				initial_delay += midi_data.header.convert_to_seconds(us_per_beat, event.delta_time)
				var note_on := event as MidiData.NoteOn
				if note_on != null:
					print("On:" + note_on.note_name)
					# TODO: wait for initial_delay and play note_on.note
					if initial_delay > 0:
						await get_tree().create_timer(initial_delay).timeout
					
					$Note.text = note_on.note_name
					initial_delay = 0
				
				var note_off := event as MidiData.NoteOff
				if note_off != null:
					print("Off:" + note_off.note_name)
