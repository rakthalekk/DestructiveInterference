class_name Beat
extends PathFollow2D

## Const ref of screen height
const SCREEN_HEIGHT = 980


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

## icon used by sprite
@onready var icon := $Icon/Icon as Sprite2D

## anim player
@onready var anim_player := $AnimationPlayer as AnimationPlayer


func _physics_process(_delta: float) -> void:
	progress += speed * _delta


func dispatch_beat(in_wave_type: GameManager.WAVE_TYPE, in_lookahead_time_seconds: float):
	wave_type = in_wave_type
	icon.frame = int(in_wave_type)
	speed = SCREEN_HEIGHT / in_lookahead_time_seconds


## kill thyself
func _on_despawn_box_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player2D:
		PlayerManager.player_take_damage()
	
	die()


func die():
	anim_player.play("my_time_has_come")
