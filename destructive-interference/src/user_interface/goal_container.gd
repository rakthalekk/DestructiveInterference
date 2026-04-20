class_name GoalContainerUI
extends Control



var current_value := 0.0
var max_value := 0.0
var goal_type: GameManager.WAVE_TYPE = GameManager.WAVE_TYPE.NONE

var progress_color: Color

@onready var fake_hedgehog := $TextureRect/RealHedgehog/FakeHedgehog as Label
@onready var real_hedgehog := $TextureRect/RealHedgehog as Label
@onready var texture_progress_bar := $TextureRect/TextureProgressBar as TextureProgressBar



func _process(_delta: float) -> void:
	if goal_type == GameManager.WAVE_TYPE.NONE || !GameManager.can_move:
		return
	
	var old_val = current_value
	current_value = LevelManager.wave_interferences[goal_type]
	
	current_value = clampf(current_value, 0, max_value)
	
	texture_progress_bar.value = current_value
	
	fake_hedgehog.text = "%d" % int(max_value - current_value)
	real_hedgehog.text = "%d" % int(max_value - current_value)
	
	if current_value > old_val:
		$HitAnimation.play("hit_anim")
		$HitAnimation.seek(0.0, true)


func setup_goal_container(in_max_value: float, in_goal_type: GameManager.WAVE_TYPE):
	max_value = in_max_value
	texture_progress_bar.max_value = max_value
	progress_color = GameManager.wave_colors[in_goal_type]
	goal_type = in_goal_type
	texture_progress_bar.tint_progress = progress_color
	real_hedgehog.modulate = progress_color
	
	$IdleAnimation.seek(randf_range(0, $IdleAnimation.current_animation_length))
	$IdleAnimation.play("idle")
