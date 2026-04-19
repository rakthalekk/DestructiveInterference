extends Line2D


## Const ref of screen height
const SCREEN_HEIGHT = 1080


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var lifetime = LevelManager.view_range
	var speed = SCREEN_HEIGHT / lifetime
	position.y += speed * delta
	
	if position.y >= SCREEN_HEIGHT:
		queue_free()
