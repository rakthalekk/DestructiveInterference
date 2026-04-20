class_name Beat
extends PathFollow2D


enum BEAT_TYPE {
	TAP,
	HOLD
}

var my_beat_type: BEAT_TYPE

signal i_die

## Wave type for this beat
var wave_type: GameManager.WAVE_TYPE


## Note describing this beat
var note: Note


## Speed value used by this beat
var speed: float

var width := 1:
	set(val):
		width = val
		$Icon.scale = Vector2(width, 1)
		$DespawnBox.scale = Vector2(width, 1)
		$Icon.position = Vector2((width - 1) * 35, 0)
		$DespawnBox.position = Vector2((width - 1) * 35, 0)
		$HurtThePlayerBox.scale = Vector2(width, 1)
		$HurtThePlayerBox.position = Vector2((width - 1) * 35, 0)


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


var being_held = false

var hold_time = 0.0

var time_to_hold = 0.0



var subdivision_timer = 0.0

var note_data: Note

var looped_audio = false


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
		$Icon/ColorRect.modulate = Color.DARK_RED
	else:
		$Icon/ColorRect.modulate = Color.WHITE
		return
	
	if hold_time >= time_to_hold && anim_player.current_animation != "my_time_has_come":
		die()
	else:
		subdivision_timer += delta
		if subdivision_timer >= LevelManager.subdivision_offset * 4:
			subdivision_timer = 0.0
			LevelManager.add_tolerance(wave_type, 0.2)


func dispatch_beat(note: Note, in_lookahead_time_seconds: float):
	note_data = note
	wave_type = note.instrument.type
	icon.frame = int(wave_type)
	$Icon/Bkgd.modulate = wave_colors[wave_type]
	$Icon/ColorRect.color = wave_colors[wave_type]
	speed = (LevelManager.SCREEN_HEIGHT - 38) / in_lookahead_time_seconds
	
	hold_time = 0.0
	time_to_hold = note.end_time - note.start_time
	
	$Icon/ColorRect.size.y = LevelManager.SCREEN_HEIGHT / LevelManager.view_range * time_to_hold
	
	if !is_zero_approx(time_to_hold):
		var shape := $HurtThePlayerBox/CollisionShape2D.shape as RectangleShape2D
		shape.size = $Icon/ColorRect.size
		$HurtThePlayerBox/CollisionShape2D.position.y -= ($Icon/ColorRect.size.y / 2)
	
	my_beat_type = BEAT_TYPE.TAP if is_zero_approx(time_to_hold) else BEAT_TYPE.HOLD 
	
	print("hold time: ", time_to_hold)
	print("my beat type: ", BEAT_TYPE.keys()[my_beat_type])


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
	i_die.emit(self)
	anim_player.play("my_time_has_come")



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
