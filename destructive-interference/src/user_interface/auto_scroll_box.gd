## Custom class for handling auto-focus following on scrolling containers with VBox children. 
## 
## Particularly those making use of "follow_focus" that wish to have more visible 
## than the immediate edge
class_name AutoScrollbox
extends ScrollContainer


## parent of children being scrolled
@export var child_container: Control = self

## Deadzone width from center for auto-scrolling with directional input
@export var deadzone_y := 50


## Getter helper for getting center of scrollbox
var center: Vector2:
	get:
		return global_position + size/2.0

## Whether we should be auto-scrolling
var _focus_dirty = false

## Whether the mouse is *hovering* (not necessarily pressing) scroll bar
var _bar_hovered = false


## Connects necessary signals
func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	var scrollbar = get_v_scroll_bar()
	scrollbar.mouse_entered.connect(_scroll_state_changed.bind(true))
	scrollbar.mouse_exited.connect(_scroll_state_changed.bind(false))


## Handles custom deadzone for scrolling
func _process(delta: float) -> void:
	if !_focus_dirty:
		return
	
	var focused = _get_focused_child()
	if !is_instance_valid(focused):
		return
	
	# don't autoscroll if touch bar is being used (this is kinda jank but works I think)
	if (_bar_hovered && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) || Input.is_action_just_released("ui_mouse_wheel"): 
		_focus_dirty = false
		return
	
	# get distance from center. if outside scrolling deadzone, increment scroll smoothly. 
	# Otherwise, this is finished so mark as clean
	var dist = focused.get_screen_position().y - center.y
	if abs(dist) > deadzone_y:
		scroll_horizontal += sign(dist) * ceil(400 * delta)
	else:
		_focus_dirty = false


## Helper for returning the currently focused child. 
func _get_focused_child() -> Control:
	var focused = get_viewport().gui_get_focus_owner()
	
	var _curr_node = focused
	while ![get_tree().root, null].has(_curr_node.get_parent()):
		if _curr_node.get_parent() == self:
			return focused
		
		_curr_node = _curr_node.get_parent()
	
	return null


## Tracks when a child focus changes, for deadzone auto-scroll handling
func _on_focus_changed(_control: Control):
	var curr_focus = _get_focused_child()
	if curr_focus == null:
		return
	
	_focus_dirty = true


## Tracks whether using the mouse (or technically finger) to scroll the bar
func _scroll_state_changed(state: bool):
	_bar_hovered = state
