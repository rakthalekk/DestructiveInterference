class_name GameMenu
extends Control


## Fires when transition is complete
signal transition_complete


## animation player for intro/outro
@onready var anim_player := $AnimationPlayer

## cached state for if the transition is complete or nah
var _transition_complete_fired := false


func transition_in():
	anim_player.play("intro")


## Call this function from anim player if you want to start next transition_in early
func emit_transition_complete():
	transition_complete.emit()
	_transition_complete_fired = true


func transition_out():
	anim_player.play("outro")
	await get_tree().create_timer(anim_player.current_animation_length).timeout
	
	if !_transition_complete_fired:
		transition_complete.emit()
		queue_free()
