## 3D representation of the player
class_name Player3D
extends Node3D


var player_2d_ref: Player2D


var target_position: Vector3


var current_lane_idx = 2

var lane_points: Array[Node3D]

@export var lane_container: Node3D


## animation playin that thanggg
@onready var dodge_anim := $DodgeAnimation as AnimationPlayer

## animation playin that thanng
@onready var move_anim := $MoveAnimation as AnimationPlayer

## animation playin that thannnnggg
@onready var damage_anim := $DamageAnimation as AnimationPlayer


func _ready() -> void:
	PlayerManager.player_3d = self
	
	var children = lane_container.get_children()
	
	for child in children:
		lane_points.push_back(child)
	
	change_lane(Vector2i.ZERO)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = global_position.lerp(target_position, 20 * delta)


## Change lane wahoopo
func change_lane(in_direction: Vector2i):
	current_lane_idx = clampi(current_lane_idx + in_direction.x, 0, 4)
	target_position = lane_points[current_lane_idx].global_position
	
	if in_direction == Vector2i.LEFT:
		move_anim.stop()
		move_anim.play("move_left")
	elif in_direction == Vector2i.RIGHT:
		move_anim.stop()
		move_anim.play("move_right")


## Dodge function for player
func dodge_input():
	dodge_anim.stop()
	dodge_anim.play("dodge")


func interfere(in_interfere_type: GameManager.WAVE_TYPE):
	pass


func on_take_damage():
	damage_anim.stop()
	damage_anim.play("take_damage")
