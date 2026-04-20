class_name InterfereBox
extends Area2D


enum STATE {
	RELEASED,
	HOLDING,
	TAPPED
}

var current_state := STATE.RELEASED

var interfere_type: GameManager.WAVE_TYPE = GameManager.WAVE_TYPE.NONE


var required_hold_type := 0.0


## its a timer. it times things
@onready var timer := $Timer as Timer

## when the collision is boxing it straight up
@onready var collision_box := $CollisionShape2D as CollisionShape2D

## icon i hardly nikon
@onready var icon := $Icon as Node2D

## preview icon icon
@onready var preview := $Icon/Icon as Sprite2D


var wave_colors: Dictionary[GameManager.WAVE_TYPE, Color] = {
	GameManager.WAVE_TYPE.TRIANGLE: Color("e04e4e"),
	GameManager.WAVE_TYPE.SQUARE: Color("40ba22"),
	GameManager.WAVE_TYPE.SAW: Color("ba228c"),
	GameManager.WAVE_TYPE.SINE: Color("2250ba"),
	GameManager.WAVE_TYPE.NOISE: Color("ffffff")
}


func _ready() -> void:
	end_interfere()


## Sets up data for interference & activates collision
func interfere(in_interfere_type: GameManager.WAVE_TYPE):
	interfere_type = in_interfere_type
	collision_box.disabled = false
	$Icon/Bkgd.modulate = wave_colors[in_interfere_type]
	preview.frame = int(in_interfere_type)
	icon.visible = true
	
	current_state = STATE.TAPPED
	
	timer.start()


func interfere_hold(in_interfere_type: GameManager.WAVE_TYPE):
	if current_state != STATE.TAPPED:
		current_state = STATE.HOLDING
		interfere_type = in_interfere_type


func interfere_release():
	end_interfere()


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
	if beat.wave_type == interfere_type:
		beat.being_held = true
	else:
		PlayerManager.on_player_missed_beat(beat)
		beat.die()


func _tap_beat_logic(beat: Beat):
	if beat.wave_type == interfere_type:
		PlayerManager.on_player_killed_beat(beat)
	else:
		PlayerManager.on_player_missed_beat(beat)
	
	PlayerManager.interfere_cooldown.stop()
	beat.die()


## Ends interference when timer times out
func _on_timer_timeout() -> void:
	current_state = STATE.HOLDING


## Ends interference 
func end_interfere():
	current_state = STATE.RELEASED
	collision_box.set_deferred("disabled", true)
	icon.visible = false
