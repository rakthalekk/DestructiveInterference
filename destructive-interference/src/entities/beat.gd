class_name Beat
extends PathFollow2D


enum BEAT_TYPE {
	TAP,
	HOLD
}

var my_beat_type: BEAT_TYPE

signal i_die
signal i_makea_the_particle(wave_type: GameManager.WAVE_TYPE)
signal kill_all_your_friends

## Wave type for this beat
var wave_type: GameManager.WAVE_TYPE


## Note describing this beat
var note: Note


## Speed value used by this beat
var speed: float

var width := 1:
	set(val):
		width = val
		$Connectors/Connector1.visible = width >= 2
		$Connectors/Connector2.visible = width >= 3
		$Connectors/Connector3.visible = width >= 4
		$Connectors/Connector4.visible = width >= 5


var friends: Array[Beat]


var wave_symbols: Dictionary[GameManager.WAVE_TYPE, Texture2D] = {
	GameManager.WAVE_TYPE.TRIANGLE: preload("res://assets/triangle.png"),
	GameManager.WAVE_TYPE.SQUARE: preload("res://assets/square.png"),
	GameManager.WAVE_TYPE.SAW: preload("res://assets/saw.png"),
	GameManager.WAVE_TYPE.SINE: preload("res://assets/sine.png"),
	GameManager.WAVE_TYPE.NOISE: preload("res://assets/noise.png")
}


var wave_colors: Dictionary[GameManager.WAVE_TYPE, Color] = {
	GameManager.WAVE_TYPE.TRIANGLE: Color("f66593"),
	GameManager.WAVE_TYPE.SQUARE: Color("3efba3"),
	GameManager.WAVE_TYPE.SAW: Color("77ffff"),
	GameManager.WAVE_TYPE.SINE: Color("fff46d"),
	GameManager.WAVE_TYPE.NOISE: Color("ffffff")
}

## icon used by sprite
@onready var icon := $Icon/Icon as Sprite2D

## anim player
@onready var anim_player := $AnimationPlayer as AnimationPlayer


var being_held = false

var hold_time = 0.0

var time_to_hold = 0.0

var why_so_holding_particle_steve_jobs = 0.0


var subdivision_timer = 0.0

var note_data: Note

var looped_audio = false

var dying = false


func _ready() -> void:
	PlayerManager.switched_lane.connect(_on_lane_changed)
	PlayerManager.interfere_released.connect(_on_interfere_released)


func _physics_process(delta: float) -> void:
	if !GameManager.can_move:
		return
	
	progress += speed * delta
	
	if my_beat_type != BEAT_TYPE.HOLD:
		return
	
	if being_held:
		hold_time += delta
		why_so_holding_particle_steve_jobs += delta
		$Icon/ColorRect.modulate = Color.DARK_RED
	else:
		$Icon/ColorRect.modulate = Color.WHITE
		return
	
	if why_so_holding_particle_steve_jobs >= 0.2:
		why_so_holding_particle_steve_jobs = 0.0
		i_makea_the_particle.emit(wave_type)
	
	if hold_time >= time_to_hold && anim_player.current_animation != "my_time_has_come":
		die()
	else:
		subdivision_timer += delta
		if subdivision_timer >= LevelManager.subdivision_offset * 4:
			subdivision_timer = 0.0
			LevelManager.add_tolerance(wave_type, 0.5)


func dispatch_beat(note: Note, in_lookahead_time_seconds: float):
	note_data = note
	wave_type = note.instrument.type
	#icon.frame = int(wave_type)
	icon.texture = wave_symbols[wave_type]
	$Connectors/Connector1.default_color = wave_colors[wave_type]
	$Connectors/Connector2.default_color = wave_colors[wave_type]
	$Connectors/Connector3.default_color = wave_colors[wave_type]
	$Connectors/Connector4.default_color = wave_colors[wave_type]
	
	$Icon/Bkgd.modulate = wave_colors[wave_type]
	$Icon/ColorRect.color = wave_colors[wave_type]
	speed = (LevelManager.SCREEN_HEIGHT) / in_lookahead_time_seconds
	
	hold_time = 0.0
	time_to_hold = note.end_time - note.start_time
	
	$Icon/ColorRect.size.y = LevelManager.SCREEN_HEIGHT / LevelManager.view_range * time_to_hold
	
	if !is_zero_approx(time_to_hold):
		var shape := $HurtThePlayerBox/CollisionShape2D.shape as RectangleShape2D
		shape.size = $Icon/ColorRect.size
		$HurtThePlayerBox/CollisionShape2D.position.y -= ($Icon/ColorRect.size.y / 2)
	
	my_beat_type = BEAT_TYPE.TAP if is_zero_approx(time_to_hold) else BEAT_TYPE.HOLD 


func add_friend(friend: Beat):
	friends.append(friend)
	friend.kill_all_your_friends.connect(die)


## kill thyself
func _on_despawn_box_area_entered(_area: Area2D) -> void:
	if my_beat_type == BEAT_TYPE.TAP:
		die()
	else:
		await get_tree().create_timer(time_to_hold).timeout
		die()


func _on_hurt_the_player_box_area_entered(_area: Area2D) -> void:
	if !being_held && anim_player.current_animation != "my_time_has_come":
		PlayerManager.on_player_missed_beat(self)
		die()


func die():
	if dying:
		return
	
	dying = true
	i_die.emit(self)
	anim_player.play("my_time_has_come")
	kill_all_your_friends.emit()


func _on_lane_changed(idx: int):
	if my_beat_type != BEAT_TYPE.HOLD || !being_held:
		return
	
	var parent_index = get_parent().get_index()
	
	if idx != parent_index:
		PlayerManager.player_take_damage()
		die()


func _on_interfere_released():
	if my_beat_type != BEAT_TYPE.HOLD || !being_held:
		return
	
	if hold_time < time_to_hold:
		PlayerManager.player_take_damage()
		die()
