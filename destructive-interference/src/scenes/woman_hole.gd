# i tried to stop it...
class_name WomanHole
extends Control


@onready var dialogue_anim := $DialogueBox/Speaking as AnimationPlayer

@onready var char_yap_anim := $TextureRect/FrameMask/yap as AnimationPlayer



func _ready() -> void:
	dialogue_anim.animation_started.connect(dialogue_anim.play.bind("yap"))
	dialogue_anim.animation_started.connect(dialogue_anim.seek.bind(randf_range(0, dialogue_anim.current_animation_length), true))
	dialogue_anim.animation_finished.connect(dialogue_anim.stop)


func display_text(in_text: String):
	$DialogueBox/Speech.text = in_text
	$DialogueBox/Speech.visible_ratio = 0
	dialogue_anim.play("speak")
