class_name Beat
extends PathFollow2D


enum BEAT_TYPE {
	TAP,
	HOLD
}

var my_beat_type: BEAT_TYPE

## Wave type for this beat
var wave_type: GameManager.WAVE_TYPE


## Speed value used by this beat
var speed: float

var width := 1:
	set(val):
		width = val
		$Icon.scale = Vector2(width, 1)
		$DespawnBox.scale = Vector2(width, 1)
		$Icon.position = Vector2((width - 1) * 72, 0)
		$DespawnBox.position = Vector2((width - 1) * 72, 0)


var height := 1:
	set(val):
		height = val

var wave_colors: Dictionary[GameManager.WAVE_TYPE, Color] = {
	GameManager.WAVE_TYPE.TRIANGLE: Color("e04e4e"),
	GameManager.WAVE_TYPE.SQUARE: Color("40ba22"),
	GameManager.WAVE_TYPE.SAW: Color("ba228c"),
	GameManager.WAVE_TYPE.SINE: Color("2250ba"),
	GameManager.WAVE_TYPE.NOISE: Color("ffffff")
}

## icon used by sprite
@onready var icon := $Icon/Icon as Sprite2D

## anim player
@onready var anim_player := $AnimationPlayer as AnimationPlayer


var hold_time = 0.0


var note_data: Note

var looped_audio = false


func _physics_process(delta: float) -> void:
	if !GameManager.can_move:
		return
	
	PlayerManager.switched_lane.connect(_on_lane_changed)
	PlayerManager.interfere_released.connect(_on_interfere_released)
	
	progress += speed * delta


func dispatch_beat(note: Note, in_lookahead_time_seconds: float):
	note_data = note
	wave_type = note.instrument.type
	icon.frame = int(wave_type)
	$Icon/Bkgd.modulate = wave_colors[wave_type]
	speed = LevelManager.SCREEN_HEIGHT / in_lookahead_time_seconds
	
	hold_time = note.end_time - note.start_time
	
	my_beat_type = BEAT_TYPE.TAP if !note.end_time else BEAT_TYPE.HOLD 


## kill thyself
func _on_despawn_box_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player2D:
		PlayerManager.player_take_damage()
	
	die()


func die():
	anim_player.play("my_time_has_come")



func _on_lane_changed(idx: int):
	if my_beat_type != BEAT_TYPE.HOLD:
		return
	
	


func _on_interfere_released():
	if my_beat_type != BEAT_TYPE.HOLD:
		return
	
	
