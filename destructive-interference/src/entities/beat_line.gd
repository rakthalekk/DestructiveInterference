extends Line2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !GameManager.can_move:
		return
	
	var lifetime = LevelManager.view_range
	var speed = (LevelManager.SCREEN_HEIGHT + 38) / lifetime
	position.y += speed * delta
	
	if position.y >= LevelManager.SCREEN_HEIGHT:
		queue_free()
