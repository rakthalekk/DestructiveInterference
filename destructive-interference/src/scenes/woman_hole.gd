# i tried to stop it...
class_name WomanHole
extends Control


@onready var dialogue_anim := $DialogueBox/Speaking as AnimationPlayer

@onready var char_yap_anim := $TextureRect/FrameMask/yap as AnimationPlayer



func _ready() -> void:
	dialogue_anim.animation_started.connect(char_yap_anim.play.bind("yap"))
	dialogue_anim.animation_started.connect(char_yap_anim.seek.bind(randf_range(0, char_yap_anim.get_animation("yap").length), true))
	dialogue_anim.animation_finished.connect(char_yap_anim.stop)


func display_text(in_text: String):
	$DialogueBox/Speech.text = in_text
	$DialogueBox/Speech.visible_ratio = 0
	dialogue_anim.play("speak")
