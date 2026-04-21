@tool
class_name GameButton
extends TextureButton


@export var is_back_btn: bool

@export_multiline var button_text: String:
	set(value):
		if !label:
			return
		
		text_val = value
		label.text = text_val
	get():
		return text_val


@export_storage var text_val = ""


@onready var label := $LabelParent/Label as Label


var hovering: bool:
	get():
		return is_hovered() || has_focus()


func _ready() -> void:
	label.text = text_val


func _process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	
	var val = size / Vector2(500.0, 500.0)
	
	if val != label.scale:
		print("rescale to ", val)
		print("pre scale val: ", label.scale)
		label.scale = val
		label.force_update_transform()
		print("scale val: ", label.scale)


func _on_pressed() -> void:
	if is_back_btn:
		AudioManager.sfx_one_shot(AudioManager.SFX_MENU_BACK)
	else:
		AudioManager.sfx_one_shot(AudioManager.SFX_MENU_SCROLL)


func _on_focus_entered() -> void:
	AudioManager.sfx_one_shot(AudioManager.SFX_MENU_SELECT)
