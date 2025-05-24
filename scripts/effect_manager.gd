extends Node

# Flash Effect that you can use anywhere
func flash(sprite: AnimatedSprite2D, color: Color, duration: float = 0.1, strength: float = 1.0) -> void:
	var mat := sprite.material as ShaderMaterial
	if not mat:
		print("ShaderMaterial not found on sprite!")
		return
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", strength)
	await sprite.get_tree().create_timer(duration).timeout
	mat.set_shader_parameter("flash_amount", 0.0)
