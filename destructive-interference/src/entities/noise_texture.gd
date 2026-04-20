class_name NoiseTexture
extends TextureRect


var textures: Array[Texture2D] = [preload("res://assets/noise_1.png"), preload("res://assets/noise_2.png"), preload("res://assets/noise_3.png")]


func pick_random_texture() -> Texture2D:
	show()
	texture = textures.pick_random()
	return texture


func set_tex(tex: Texture2D):
	show()
	texture = tex
