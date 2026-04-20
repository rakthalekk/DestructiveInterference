class_name InterfereBox
extends Area2D


enum STATE {
	RELEASED,
	HOLDING,
	TAPPED
}


const HURT_ON_MISS = false

var current_state := STATE.RELEASED

var interfere_type: GameManager.WAVE_TYPE = GameManager.WAVE_TYPE.NONE

var interfere_type_2: GameManager.WAVE_TYPE = GameManager.WAVE_TYPE.NONE

var required_hold_type := 0.0

var has_hit_note = false

## its a timer. it times things
@onready var timer := $Timer as Timer

## when the collision is boxing it straight up
@onready var collision_box := $CollisionShape2D as CollisionShape2D

## icon i hardly nikon
@onready var icon := $Icon as Node2D

## preview icon icon
@onready var preview := $Icon/Icon as Sprite2D


var wave_colors: Dictionary[GameManager.WAVE_TYPE, Color] = {
	GameManager.WAVE_TYPE.TRIANGLE: Color("f66593"),
	GameManager.WAVE_TYPE.SQUARE: Color("3efba3"),
	GameManager.WAVE_TYPE.SAW: Color("77ffff"),
	GameManager.WAVE_TYPE.SINE: Color("fff46d"),
	GameManager.WAVE_TYPE.NOISE: Color("ffffff"),
	GameManager.WAVE_TYPE.NONE: Color("ffffff")
}


func _ready() -> void:
	stop_interfere()
	LevelManager.game_over.connect(_on_game_over)


## Sets up data for interference & activates collision
func interfere(in_interfere_type: GameManager.WAVE_TYPE):
	if interfere_type != GameManager.WAVE_TYPE.NONE:
		interfere_type_2 = in_interfere_type
	else:
		interfere_type = in_interfere_type
		preview.modulate = wave_colors[in_interfere_type]
	
	update_interfere_icons()
	
	has_hit_note = false
	collision_box.disabled = false
	icon.visible = true
	
	current_state = STATE.TAPPED
	
	timer.start()


func interfere_hold(in_interfere_type: GameManager.WAVE_TYPE):
	if current_state != STATE.TAPPED:
		current_state = STATE.HOLDING
		#interfere_type = in_interfere_type


func interfere_release(in_interfere_type: GameManager.WAVE_TYPE):
	end_interfere(in_interfere_type)


## If detects collision w/ a beat, take dmg or nah & end interference
func _on_area_entered(area: Area2D) -> void:
	var beat = area.get_parent()
	if beat is not Beat:
		return
	
	beat = beat as Beat
	
	if beat.my_beat_type == Beat.BEAT_TYPE.HOLD:
		_hold_beat_logic(beat)
	else:
		_tap_beat_logic(beat)


func _hold_beat_logic(beat: Beat):
	if (beat.wave_type == interfere_type || beat.wave_type == interfere_type_2) && current_state == STATE.TAPPED:
		beat.being_held = true
		has_hit_note = true
	else:
		return
		#PlayerManager.on_player_missed_beat(beat)
		#beat.die()


func _tap_beat_logic(beat: Beat):
	if (beat.wave_type == interfere_type || beat.wave_type == interfere_type_2) && current_state == STATE.TAPPED:
		PlayerManager.on_player_killed_beat(beat)
		has_hit_note = true
	else:
		return
		#PlayerManager.on_player_missed_beat(beat)
	
	PlayerManager.interfere_cooldown.stop()
	beat.die()


## Ends interference when timer times out
func _on_timer_timeout() -> void:
	current_state = STATE.HOLDING


func update_interfere_icons():
	preview.modulate = wave_colors[interfere_type]
	$Icon/Icon2.modulate = wave_colors[interfere_type_2]
	$Icon/Icon2.visible = interfere_type_2 != GameManager.WAVE_TYPE.NONE


## Ends interference 
func end_interfere(in_interfere_type: GameManager.WAVE_TYPE):
	if interfere_type == in_interfere_type && interfere_type_2 != GameManager.WAVE_TYPE.NONE:
		interfere_type = interfere_type_2
		interfere_type_2 = GameManager.WAVE_TYPE.NONE
		update_interfere_icons()
	elif interfere_type_2 == in_interfere_type:
		interfere_type_2 = GameManager.WAVE_TYPE.NONE
		update_interfere_icons()
	elif interfere_type == in_interfere_type:
		stop_interfere()
	
	if HURT_ON_MISS && !has_hit_note:
		PlayerManager.on_player_missed_beat(null)


func _on_game_over(_is_win: bool):
	stop_interfere()


func stop_interfere():
	current_state = STATE.RELEASED
	collision_box.set_deferred("disabled", true)
	icon.visible = false
	interfere_type = GameManager.WAVE_TYPE.NONE
	interfere_type_2 = GameManager.WAVE_TYPE.NONE
	update_interfere_icons()
