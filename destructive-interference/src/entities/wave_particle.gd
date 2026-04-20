class_name WaveParticle
extends CPUParticles2D


var wave_type: GameManager.WAVE_TYPE:
	set(val):
		wave_type = val
		get_random_texture()


var particle_idx_by_wave_type: Dictionary[GameManager.WAVE_TYPE, int] = {
	GameManager.WAVE_TYPE.SINE: 2,
	GameManager.WAVE_TYPE.SQUARE: 3,
	GameManager.WAVE_TYPE.SAW: 4,
	GameManager.WAVE_TYPE.TRIANGLE: 5,
}


func _ready() -> void:
	emitting = true


func get_random_texture():
	var idx: int
	var rand = randf()
	if rand < 0.1:
		idx = 0
	elif rand < 0.2:
		idx = 1
	else:
		idx = particle_idx_by_wave_type[wave_type]
	
	texture.region.position = Vector2(25 * idx, 0)


func _on_finished() -> void:
	queue_free()
