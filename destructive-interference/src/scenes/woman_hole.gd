# i tried to stop it...
class_name WomanHole
extends Control


@onready var dialogue_anim := $DialogueBox/Speaking as AnimationPlayer

@onready var char_yap_anim := $TextureRect/FrameMask/yap as AnimationPlayer



func _ready() -> void:
	dialogue_anim.animation_started.connect(_play_yap)
	
	if scale.x < 0:
		$DialogueBox/Speech.scale.x *= -1


func _play_yap(_name):
	char_yap_anim.play("yap")
	char_yap_anim.seek(randf_range(0, char_yap_anim.get_animation("yap").length), true)


func _cease_yap_scale_anim():
	char_yap_anim.stop()


func yap(in_text: String):
	$DialogueBox/Speech.text = in_text
	$DialogueBox/Speech.visible_ratio = 0
	dialogue_anim.stop()
	dialogue_anim.play("speak")
