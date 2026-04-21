class_name Lane
extends Path2D

## wavelength of drawn waves, in y pixel height
const WAVE_PERIOD_PX := 60
## y-height of line segments drawn.
## WAVE_PERIOD_PX / Y_RESOLUTION_PX = # segments per waveform.
const Y_RESOLUTION_PX := 3
# it'll make things easier if Y_RESOLUTION_PX is a factor of WAVE_PERIOD_PX.
# for now I'm encoding that as an assumption in _ready()

## Number of line segments which will be rendered in one subdivision. Higher number = better fidelity
const SEGMENTS_PER_SUBDIVISION := 12.0 # TODO: try tweaking

## Total amplitude of waveforms drawn
const X_AMPLITUDE_PX := 24

## width of the track line drawn
const LINE_WIDTH_PX := 8.0

const COLOR_EMPTY = Color.WHITE

## Seconds indicating something occurs at the end of the track
const END_OF_TRACK_TIME_SENTINEL := INF


var lane_idx: int

## List of beats currently rendered on this Lane.
## Front of array is the closest upcoming beat, then later entries are further away.
var beats: Array[Beat] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# check assumptions
	@warning_ignore("assert_always_true")
	assert(WAVE_PERIOD_PX % 2 == 0, "lane.gd currently assumes WAVE_PERIOD_PX is an even number for sake of cleanly drawing square waves. Please either restore this constraint or figure out how to update the line drawing code :)")
	@warning_ignore("integer_division", "assert_always_true")
	assert((WAVE_PERIOD_PX / 2) % Y_RESOLUTION_PX == 0, "lane.gd currently assumes Y_RESOLUTION_PX will be a factor of (WAVE_PERIOD_PX / 2) for sake of line drawing. Please either restore this constraint or figure out how to update the line drawing code :)")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	pass

enum LineStyle { EMPTY, LINEAR, COMPLEX }

var last_update := 0.0

var draw_count := 0
const DRAWS_TO_CYCLE_WAVE = 3

func _draw() -> void:
	draw_count += 1
	# y = 0 is `view_range` seconds ahead of `current_time` in the song
	# y = SCREEN_HEIGHT is `current_time` in the song
	var top_of_path := self.curve.get_point_position(0) # small number, top of screen
	var bottom_of_path := self.curve.get_point_position(1) # big number, bottom of screen
	assert(top_of_path.x == 0)
	assert(bottom_of_path.x == 0)
	var debug_log := false
	#if LevelManager.current_time > last_update + 1.0:
		#debug_log = true
		#last_update = LevelManager.current_time
	
	#if debug_log: print("draw_count=%d" % [draw_count])

	var beats_per_subdivision := 1 / LevelManager.subdivisions_per_beat

	# simple case: no beats to draw
	if beats.size() == 0:
		draw_line(bottom_of_path, top_of_path, COLOR_EMPTY, LINE_WIDTH_PX)
		return

	if debug_log: print("start of _draw(), complicated line")
	# animate from bottom_of_path to top_of_path
	#var next_beat_idx := 0
	#var next_beat: Beat = beats.get(next_beat_idx)
	var points: PackedVector2Array = []
	var colors: PackedColorArray = []

	# draw empty line up until first beat
	var ypos_of_initial_note_start := _time_to_ypos(self.beats[0].note.start_time)
	points.append_array([
		Vector2(0, bottom_of_path.y),
		Vector2(0, _time_to_ypos(self.beats[0].note.start_time)),
	])
	colors.append_array([COLOR_EMPTY, COLOR_EMPTY])

	var beat_idx := 0
	var active_beats: Array[Beat] = []
	var last_y_drawn := ypos_of_initial_note_start
	while beat_idx < self.beats.size():
		if debug_log: print("  top of beat loop. beat_idx=%d" % [beat_idx])
		# goal: draw all line segments until the earliest of (
		#   this beat ends
		#   next beat starts
		# )
		# at shortest, draw one subdivision i.e. one wave period

		# find all beats which start around the same time (~ the same subdivision)
		var cur_start_time := self.beats[beat_idx].note.start_time
		while beat_idx < self.beats.size() and is_equal_approx(self.beats[beat_idx].note.start_time, cur_start_time): # for floating point errors
			if debug_log: print("    adding beat to this iteration")
			active_beats.append(self.beats[beat_idx])
			beat_idx += 1

		# figure out when the *next* beat will start, for sake of rendering the full span of current notes
		var next_beat_start_time := (self.beats[beat_idx].note.start_time
				if beat_idx < self.beats.size()
				else END_OF_TRACK_TIME_SENTINEL)

		# render subdivisions for any notes (short or held) which end before the next note start
		# render one subdivision at a time
		var subdivision_idx := 0
		var initial_y_pos := _time_to_ypos(active_beats[0].note.start_time)
		while active_beats.any(func(beat: Beat) -> bool: return (
					beat.note.end_time == null
					or is_less_or_equal_approx(beat.note.end_time, next_beat_start_time))):
			var start_y_pos = initial_y_pos - _beat_duration_to_y_diff(subdivision_idx * beats_per_subdivision)
			var end_y_pos := initial_y_pos - _beat_duration_to_y_diff((subdivision_idx + 1) * beats_per_subdivision)
			if debug_log: print("    top of middle while loop. drawing one full subdivision. subdivision_idx=%d, active_beats.size()=%d, start_y_pos=%f, end_y_pos=%f" % [subdivision_idx, active_beats.size(), start_y_pos, end_y_pos])

			# render all segments for this subdivision
			var avg_color_for_subdivision = avg_color(active_beats.map(func(beat: Beat) -> Color: return beat.get_appropriate_color()))
			# make one point to separate the color of this waveform
			#points.append(Vector2(0.0, last_y_drawn))
			#colors.append(avg_color_for_subdivision)
			#if debug_log: print("      adding new point for start of colored segment at %s with color %s" % [points[-1], colors[-1]])
			var latest_x_pos := 0.0
			var period_offset := int(draw_count / DRAWS_TO_CYCLE_WAVE) % int(SEGMENTS_PER_SUBDIVISION)
			# check for any beats with jumpy waveforms
			#var saw_beats := active_beats.filter(func(beat: Beat) -> bool: return beat.note.instrument.type == GameManager.WAVE_TYPE.SAW)
			#var square_beats := active_beats.filter(func(beat: Beat) -> bool: return beat.note.instrument.type == GameManager.WAVE_TYPE.SQUARE)
			## if any jumpy waveforms, add an extra horizontal line
			#if saw_beats.size() > 0 or square_beats.size() > 0:
			#print("period_offset=%d" % [period_offset])
			points.append(Vector2(X_AMPLITUDE_PX * eval_avg(period_offset, active_beats), last_y_drawn))
			colors.append(avg_color_for_subdivision)
			if debug_log: print("      adding horizontal point for jumpy waveform at beginning of subdivision at %s with color %s" % [points[-1], colors[-1]])
			for segment_idx in range(int(SEGMENTS_PER_SUBDIVISION)):
				#var segment_idx := ((i + (draw_count % DRAWS_TO_CYCLE_WAVE)) % int(SEGMENTS_PER_SUBDIVISION))
				var period_idx := (segment_idx + period_offset) % int(SEGMENTS_PER_SUBDIVISION)
				if debug_log: print("      top of segment for-loop, segment_idx=%d" % [segment_idx])
				var pct_thru = (period_idx + 1) / SEGMENTS_PER_SUBDIVISION
				# compute new wave position
				var new_x_pos = X_AMPLITUDE_PX * eval_avg(pct_thru, active_beats)
				var new_y_pos = start_y_pos - _beat_duration_to_y_diff(((segment_idx + 1) / SEGMENTS_PER_SUBDIVISION) * beats_per_subdivision)

				# check if we need to draw any horizontal lines
				if period_idx % int(SEGMENTS_PER_SUBDIVISION / 2) == 0:
					var jumped_x_pos := X_AMPLITUDE_PX * eval_avg((period_idx + 0.01) / SEGMENTS_PER_SUBDIVISION, active_beats)
					points.append(Vector2(jumped_x_pos, last_y_drawn))
					colors.append(avg_color_for_subdivision)
					if debug_log: print("        adding extra horizontal point for jumpy waveform in middle of subdivision at %s with color %s" % [points[-1], colors[-1]])
					latest_x_pos = new_x_pos

				# add new point for this segment
				points.append(Vector2(new_x_pos, new_y_pos))
				colors.append(avg_color_for_subdivision)
				if debug_log: print("        adding normal point in subdivision at %s with color %s" % [points[-1], colors[-1]])
				last_y_drawn = new_y_pos
				latest_x_pos = new_x_pos

			# if any saw or square beats, draw the finishing line back to midpoint
			#if saw_beats.size() > 0 or square_beats.size() > 0:
			#points.append(Vector2(0.0, last_y_drawn))
			#colors.append(avg_color_for_subdivision)
			#if debug_log: print("      adding extra horizontal point for jumpy waveform at end of subdivision at %s with color %s" % [points[-1], colors[-1]])
			last_y_drawn = end_y_pos

			# clean up notes which end this subdivision
			var to_remove = []
			for active_beat in active_beats:
				# clean up any single-hit notes
				if active_beat.note.end_time == null:
					to_remove.append(active_beat)
				# clean up any longer notes which end here
				elif is_greater_or_equal_approx(_time_to_ypos(active_beat.note.end_time), end_y_pos):
					to_remove.append(active_beat)
			for b in to_remove:
				active_beats.erase(b)

			# move to next subdivision
			subdivision_idx += 1

		# now, active_beats should be empty.
		# check: do we have dead space before the next note start?
		var latest_secs_rendered := cur_start_time + subdivision_idx * LevelManager.duration_subdivision
		if !is_greater_or_equal_approx(latest_secs_rendered, next_beat_start_time):
			# render empty space until next note
			var end_of_empty_y := (_time_to_ypos(next_beat_start_time)
				if next_beat_start_time != END_OF_TRACK_TIME_SENTINEL
				else top_of_path.y)
			points.append_array([
				Vector2(0, last_y_drawn),
				Vector2(0, end_of_empty_y)
			])
			colors.append_array([COLOR_EMPTY, COLOR_EMPTY])
			if debug_log: print("    adding two points for empty stretch at %s, %s with color %s, %s" % [points[-2], points[-1], colors[-2], colors[-1]])
			last_y_drawn = end_of_empty_y

		# now, we've drawn all points up until the next beat OR the end of the beats. all done with the loop!
		continue # this is redundant but it makes me feel nice to remind that we're in a loop

	# all points and colors have been defined.
	# draw the freakin line!!!
	if debug_log:
		var disp_str := "end of draw()!!!"
		for i in range(points.size()):
			disp_str += "\n  point=%12s         color=%s" % [points[i], colors[i]]
		print(disp_str)
	draw_polyline_colors(points, colors, LINE_WIDTH_PX)

func _beat_duration_to_y_diff(num_beats: float) -> float:
	# there are a total of `LevelManager.view_range_beats` beats on screen
	# the screen spans `LevelManager.SCREEN_HEIGHT` pixels
	return num_beats * LevelManager.SCREEN_HEIGHT / LevelManager.view_range_beats

func _time_to_ypos(t_sec: float) -> float:
	# y = 0 is `view_range` seconds ahead of `current_time` in the song
	# y = SCREEN_HEIGHT is `current_time` in the song
	var sec_ahead_of_current := t_sec - LevelManager.current_time
	var pct_from_current_to_top = sec_ahead_of_current / LevelManager.view_range
	var pct_from_top_to_current = (1 - pct_from_current_to_top)
	var y_pos = pct_from_top_to_current * LevelManager.SCREEN_HEIGHT
	#print("_time_to_ypos(t_sec=%.2f): current_time=%.2f, sec_ahead_of_current=%.2f, pct_from_current_to_top=%.1f, y_pos=%.1f" % [t_sec, LevelManager.current_time, sec_ahead_of_current, pct_from_current_to_top, y_pos])
	return y_pos - 10.0 # magic number dont woooooorrry about itttt

func add_beat(beat: Beat, add_child: bool=true) -> void:
	if add_child: self.add_child(beat)
	beat.i_die.connect(_handle_beat_die)
	beats.append(beat)

func _handle_beat_die(beat: Beat) -> void:
	beats.erase(beat)


func is_greater_or_equal_approx(a: float, b: float) -> bool:
	return a > b or is_equal_approx(a, b)

func is_less_or_equal_approx(a: float, b: float) -> bool:
	return a < b or is_equal_approx(a, b)


func avg_color(colors: Array) -> Color:
	var r = 0
	var g = 0
	var b = 0
	for color: Color in colors:
		r += color.r
		g += color.g
		b += color.b
	r /= len(colors)
	g /= len(colors)
	b /= len(colors)
	return Color(r, g, b)


func eval_avg(x: float, active_beats: Array[Beat]) -> float:
	var pos = 0.0
	for beat in active_beats:
		pos += eval_beat(x, beat)
	pos /= active_beats.size()
	return pos

func eval_beat(x: float, beat: Beat) -> float:
	var type = beat.note.instrument.type
	match type:
		GameManager.WAVE_TYPE.TRIANGLE:
			return eval_triangle(x)
		GameManager.WAVE_TYPE.SINE:
			return eval_sin(x)
		GameManager.WAVE_TYPE.SQUARE:
			return eval_square(x)
		GameManager.WAVE_TYPE.SAW:
			return eval_saw(x)
		GameManager.WAVE_TYPE.NOISE:
			return 0
		_:
			printerr("lane.gd, eval_beat(): Unknown wave type %s" % [type])
			return 0.0


## Evaluate a triangle wave with domain [0, 1] and range [-1, 1], with f(0) = 0 and iniital slope positive (f(0.25) = 1)
func eval_triangle(x: float) -> float:
	x = fmod(x, 1.0)
	return -4 * abs(fmod(x+0.25, 1) - 1.0/2) + 1

## Evaluate a sin wave with domain [0, 1] and range [-1, 1], with f(0) = 0 and initial slops positive (f(0.25) = 1)
func eval_sin(x: float) -> float:
	x = fmod(x, 1.0)
	return sin(x * 2 * PI)

## Evaluate a square wave with domain [0, 1] and range [-1, 1], initially high
func eval_square(x: float) -> float:
	x = fmod(x, 1.0)
	if ! is_less_or_equal_approx(x, 0.5):
		return -1.0
	else:
		return 1.0

## Evaluate a saw wave with domain [0, 1] and range [-1, 1], slope positive
func eval_saw(x: float) -> float:
	x = fmod(x, 1.0)
	return x * -2 + 1
