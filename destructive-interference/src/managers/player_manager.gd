## Class responsible for managing the 2D & 3D representations of the player
extends Node


enum BUFFER_STATE {
	NONE,
	DODGE
}

## currently buffered action
var curr_buffer = BUFFER_STATE.NONE


## Current lane player is in
var current_lane_idx = 2

## Player 2D Ref
@export var player_2d: Player2D

## Player 3D Ref
@export var player_3d: Player3D



## animation playin that thanggg
@onready var dodge_anim := $DodgeAnimation as AnimationPlayer

## animation playin that thanng
@onready var move_anim := $MoveAnimation as AnimationPlayer

## timer for dodge i-frames
@onready var dodge_timer := $DodgeTimer as Timer

## timer used for input buffer
@onready var buffer_timer := $BufferTimer as Timer

## cooldown timer btwn movement
@onready var move_cooldown := $MoveCooldown as Timer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_process_input()


## helper for processing player inputs
func _process_input():
	if Input.is_action_pressed("move_left"):
		_change_lane(Vector2.LEFT)
	
	if Input.is_action_pressed("move_right"):
		_change_lane(Vector2.RIGHT)
	
	# allow dodge to be held
	if Input.is_action_just_pressed("dodge"):
		_dodge_input()


## Change lane wahoopo
func _change_lane(in_direction: Vector2i):
	if !move_cooldown.is_stopped():
		return
	
	player_2d.change_lane(in_direction)
	player_3d.change_lane(in_direction)
	
	move_cooldown.start()


## Dodge function for player
func _dodge_input():
	if !dodge_timer.is_stopped():
		curr_buffer = BUFFER_STATE.DODGE
		buffer_timer.start()
		return
	
	player_2d.dodge_input()
	player_3d.dodge_input()
	
	dodge_timer.start()


func _on_dodge_timer_timeout() -> void:
	player_2d.on_dodge_timer_timeout()


func _on_buffer_timer_timeout() -> void:
	match curr_buffer:
		BUFFER_STATE.DODGE:
			_dodge_input()
	
	curr_buffer = BUFFER_STATE.NONE
