## Class responsible for managing the 2D & 3D representations of the player
extends Node


###############################
##      CLASS CONSTANTS      ##           
###############################

## maximum allowed decay
const MAX_GAIN = 100

## amount gain decays over time per second
const GAIN_DECAY_RATE = 2.5


enum BUFFER_STATE {
	NONE,
	DODGE,
	INTERFERE
}

## currently buffered action
var curr_buffer = BUFFER_STATE.NONE

## interfere buffer type
var interfere_buffer_type: GameManager.WAVE_TYPE = GameManager.WAVE_TYPE.NONE

## Current lane player is in
var current_lane_idx = 2

## Player 2D Ref
@export var player_2d: Player2D

## Player 3D Ref
@export var player_3d: Player3D


## Amount of gain the player currently has
var current_gain := 0.0



## timer for dodge i-frames
@onready var dodge_timer := $DodgeTimer as Timer

## timer used for input buffer
@onready var buffer_timer := $BufferTimer as Timer

## cooldown timer btwn movement
@onready var move_cooldown := $MoveCooldown as Timer

## cooldown after taking damage before damage can be taken again
@onready var damage_cooldown := $DamageCooldown as Timer

## cooldown after damage cooldown before gain starts to decay
@onready var gain_decay_cooldown := $GainDecayCooldown as Timer

## cooldown after using interfere ability
@onready var interfere_cooldown := $InterfereCooldown as Timer


## whether player is DEAD
var dead = false


func _ready() -> void:
	GameManager.transitioned_game_state.connect(_on_state_transition)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dead || GameManager.current_game_state != GameManager.GAME_STATE.IN_GAME:
		return
	
	if Input.is_action_just_pressed("pause"):
		GameManager.transition_to(GameManager.GAME_STATE.PAUSED)
	
	_process_move_inputs()
	_process_interfere_inputs()
	
	if damage_cooldown.is_stopped() && gain_decay_cooldown.is_stopped():
		current_gain -= GAIN_DECAY_RATE * delta
	
	current_gain = clampf(current_gain, 0.0, MAX_GAIN)


## helper for processing player inputs
func _process_move_inputs():
	# allow move to be held
	if Input.is_action_just_pressed("move_left"):
		_change_lane(Vector2.LEFT, true)
	elif Input.is_action_pressed("move_left"):
		_change_lane(Vector2.LEFT)
	
	if Input.is_action_just_pressed("move_right"):
		_change_lane(Vector2.RIGHT, true)
	elif Input.is_action_pressed("move_right"):
		_change_lane(Vector2.RIGHT)
	
	if !interfere_cooldown.is_stopped():
		return # don't allow dodge while interfering
	
	if Input.is_action_just_pressed("dodge"):
		_dodge_input()


func _process_interfere_inputs():
	if !dodge_timer.is_stopped():
		return
	
	if Input.is_action_just_pressed("interfere_triangle"):
		_interfere(GameManager.WAVE_TYPE.TRIANGLE)
	
	if Input.is_action_just_pressed("interfere_square"):
		_interfere(GameManager.WAVE_TYPE.SQUARE)
	
	if Input.is_action_just_pressed("interfere_saw"):
		_interfere(GameManager.WAVE_TYPE.SAW)
		
	if Input.is_action_just_pressed("interfere_sine"):
		_interfere(GameManager.WAVE_TYPE.SINE)


## Change lane wahoopo
func _change_lane(in_direction: Vector2i, force := false):
	if !move_cooldown.is_stopped() && !force:
		return
	
	if is_instance_valid(player_2d):
		player_2d.change_lane(in_direction)
	
	if is_instance_valid(player_3d):
		player_3d.change_lane(in_direction)
	
	move_cooldown.start()


## Dodge function for player
func _dodge_input(force := false):
	if !dodge_timer.is_stopped() && !force:
		curr_buffer = BUFFER_STATE.DODGE
		buffer_timer.start()
		print('buffer_dodge')
		return
	
	if is_instance_valid(player_2d):
		player_2d.dodge_input()
	
	if is_instance_valid(player_3d):
		player_3d.dodge_input()
	
	dodge_timer.start()


func _on_dodge_timer_timeout() -> void:
	if is_instance_valid(player_2d):
		player_2d.on_dodge_timer_timeout()
	
	if !buffer_timer.is_stopped() && curr_buffer == BUFFER_STATE.DODGE:
		print("dodge from buffer")
		curr_buffer = BUFFER_STATE.NONE
		_dodge_input(true)


func _interfere(in_interfere_type: GameManager.WAVE_TYPE, force := false):
	if !interfere_cooldown.is_stopped() && !force:
		curr_buffer = BUFFER_STATE.INTERFERE
		interfere_buffer_type = in_interfere_type
		buffer_timer.start()
		return
	
	if is_instance_valid(player_2d):
		player_2d.interfere(in_interfere_type)
	
	if is_instance_valid(player_3d):
		player_3d.interfere(in_interfere_type)
	
	interfere_cooldown.start()


func on_player_killed_beat(beat: Beat):
	print("player hit")
	LevelManager.add_tolerance(beat.wave_type)


func on_player_missed_beat(_beat: Beat):
	print("player miss")
	player_take_damage()


func player_take_damage(in_damage := 10.0):
	if dead || GameManager.current_game_state != GameManager.GAME_STATE.IN_GAME:
		return
	
	if !damage_cooldown.is_stopped():
		return
	
	current_gain += in_damage
	if current_gain >= MAX_GAIN:
		_defeat()
		return
	
	gain_decay_cooldown.stop()
	damage_cooldown.start()
	
	if is_instance_valid(player_2d):
		player_2d.on_take_damage()
	
	if is_instance_valid(player_3d):
		player_3d.on_take_damage()


func _defeat():
	print("player die now wahoo")
	LevelManager.lose()
	GameManager.transition_to(GameManager.GAME_STATE.GAME_OVER)
	dead = true


func _on_interfere_cooldown_timeout() -> void:
	if !buffer_timer.is_stopped() && curr_buffer == BUFFER_STATE.INTERFERE:
		print("interfere from buffer")
		curr_buffer = BUFFER_STATE.NONE
		_interfere(interfere_buffer_type, true)
		interfere_buffer_type = GameManager.WAVE_TYPE.NONE


func _on_buffer_timer_timeout() -> void:
	print("buffer end")
	curr_buffer = BUFFER_STATE.NONE
	interfere_buffer_type = GameManager.WAVE_TYPE.NONE


func _on_state_transition(_from: GameManager.GAME_STATE, to: GameManager.GAME_STATE):
	if to == GameManager.GAME_STATE.IN_GAME:
		dead = false
		current_gain = 0.0
