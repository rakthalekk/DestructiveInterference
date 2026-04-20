@tool
class_name ControlsIcon
extends TextureRect


@export_multiline var button_text: String:
	set(value):
		if !label:
			return
		
		text_val = value
		label.text = text_val
	get():
		return text_val


@export_storage var text_val = ""

@onready var label := $Label as Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = text_val
	
	if Engine.is_editor_hint():
		return
	
	$IdleWiggle.seek(randf_range(0, $IdleWiggle.current_animation_length), true)
	$IdlePulse.seek(randf_range(0, $IdlePulse.current_animation_length), true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
