# i tried to stop it...
class_name WomanHole
extends Control


@onready var dialogue_anim := $DialogueBox/Speaking as AnimationPlayer

@onready var char_yap_anim := $TextureRect/FrameMask/yap as AnimationPlayer


@export var norm_talk: AudioStream
@export var polic_talk: AudioStream
@export var bitch_talk: AudioStream


var norm_tex := preload("res://assets/player_portrait.png") 

var polic_tex := preload("res://assets/fun_police.png")

var bitch_tex = preload("res://assets/music_bitch.png")



@onready var curr_talk_fx := norm_talk

var sfx_player_cache: AudioStreamPlayer = null


func set_bitch():
	$TextureRect/FrameMask/Woman.texture = bitch_tex
	curr_talk_fx = bitch_talk


func set_police():
	$TextureRect/FrameMask/Woman.texture = polic_tex
	curr_talk_fx = polic_talk


func set_woman():
	$TextureRect/FrameMask/Woman.texture = norm_tex
	curr_talk_fx = norm_talk



func _play_talk_sfx():
	var vol_mod = 1
	sfx_player_cache = AudioManager.sfx_one_shot(curr_talk_fx, vol_mod, randf_range(0.95, 1.05))
	sfx_player_cache.seek(randf_range(0, 0.5 * sfx_player_cache.stream.get_length()))



func _ready() -> void:
	dialogue_anim.animation_started.connect(_play_yap)
	
	if scale.x < 0:
		$DialogueBox/Speech.scale.x *= -1


func _play_yap(_name):
	char_yap_anim.play("yap")
	char_yap_anim.seek(randf_range(0, char_yap_anim.get_animation("yap").length), true)


func _cease_yap_scale_anim():
	char_yap_anim.stop()
	if is_instance_valid(sfx_player_cache):
		sfx_player_cache.queue_free()


func yap(in_text: String):
	$DialogueBox/Speech.text = in_text
	$DialogueBox/Speech.visible_ratio = 0
	dialogue_anim.stop()
	dialogue_anim.play("speak")
