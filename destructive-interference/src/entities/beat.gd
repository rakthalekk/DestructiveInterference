class_name Beat
extends PathFollow2D


const SCREEN_HEIGHT = 1080


var speed = 10


func _physics_process(_delta: float) -> void:
	progress += speed * _delta


func dispatch_beat(in_lookahead_time_seconds: float):
	speed = SCREEN_HEIGHT / in_lookahead_time_seconds


## kill thyself
func _on_despawn_box_area_entered(_area: Area2D) -> void:
	queue_free()
