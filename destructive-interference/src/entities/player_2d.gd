class_name Player2D
extends Node2D


## owning beat map for this player 2d
var owning_beat_map: BeatMap


## Current lane the player is in, idx 0-4
var current_lane_idx: int = 2


## Position the player is currently moving towards, used for lerp
var target_position: Vector2


## Hitbox used for player damage
@onready var hurt_box := $HurtBox as Area2D

## Collision shape used by [member hurt_box]
@onready var hurt_box_collider := $HurtBox/CollisionShape2D as CollisionShape2D

## Collision box used for interference
@onready var interfere_box := $InterfereBox as InterfereBox


func _ready() -> void:
	PlayerManager.player_2d = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.x = lerpf(global_position.x, target_position.x, 20 * delta)


## Dodge function for player
func dodge_input():
	hurt_box_collider.disabled = true


## Change lane 2d player is in
func change_lane(in_direction: Vector2i):
	current_lane_idx = clampi(current_lane_idx + in_direction.x, owning_beat_map.LANE_MIN, owning_beat_map.LANE_MAX)
	target_position = owning_beat_map.get_player_position_for_lane(current_lane_idx)


## Called by beatmap when it is [signal ready]
func initialize_from_beatmap(in_beat_map: BeatMap, in_lane_idx: int, in_target_pos: Vector2):
	owning_beat_map = in_beat_map
	current_lane_idx = in_lane_idx
	target_position = in_target_pos


## Resets collision information
func on_dodge_timer_timeout():
	hurt_box_collider.disabled = false


func interfere(in_interfere_type: GameManager.WAVE_TYPE):
	interfere_box.interfere(in_interfere_type)


func interfere_hold(in_interfere_type: GameManager.WAVE_TYPE):
	interfere_box.interfere_hold(in_interfere_type)


func interfere_release(in_interfere_type: GameManager.WAVE_TYPE):
	interfere_box.interfere_release(in_interfere_type)


func on_take_damage():
	pass
