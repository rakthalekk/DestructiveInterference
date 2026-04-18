class_name Player2D
extends Node2D


## owning beat map for this player 2d
var owning_beat_map: BeatMap


## Current lane the player is in, idx 0-4
var current_lane_idx: int = 2


## Position the player is currently moving towards, used for lerp
var target_position: Vector2

## Timer used for dodge hitbox NOTE: will likely be animation driven l8r
@onready var dodge_timer := $DodgeTimer as Timer

## cooldown between allowed dodges
@onready var dodge_cooldown_timer := $DodgeCooldown as Timer

## Hitbox used for player damage
@onready var hurt_box := $HurtBox as Area2D

## Collision shape used by [member hurt_box]
@onready var hurt_box_collider := $HurtBox/CollisionShape2D as CollisionShape2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_process_input()
	
	global_position.x = lerpf(global_position.x, target_position.x, 20 * delta)


## helper for processing player inputs
func _process_input():
	if Input.is_action_just_pressed("move_left"):
		_change_lane(Vector2.LEFT)
	
	if Input.is_action_just_pressed("move_right"):
		_change_lane(Vector2.RIGHT)
	
	# allow dodge to be held
	if Input.is_action_pressed("dodge"):
		_dodge_input()


## Dodge function for player
func _dodge_input():
	if !dodge_timer.is_stopped() || !dodge_cooldown_timer.is_stopped():
		return
	
	dodge_timer.start()
	hurt_box_collider.disabled = true


func _change_lane(in_direction: Vector2i):
	current_lane_idx = clampi(current_lane_idx + in_direction.x, owning_beat_map.LANE_MIN, owning_beat_map.LANE_MAX)
	target_position = owning_beat_map.get_player_position_for_lane(current_lane_idx)


## Called by beatmap when it is [signal ready]
func initialize_from_beatmap(in_beat_map: BeatMap, in_lane_idx: int, in_target_pos: Vector2):
	owning_beat_map = in_beat_map
	current_lane_idx = in_lane_idx
	target_position = in_target_pos


## Resets collision information
func _on_dodge_timer_timeout() -> void:
	hurt_box_collider.disabled = false
	dodge_cooldown_timer.start()
