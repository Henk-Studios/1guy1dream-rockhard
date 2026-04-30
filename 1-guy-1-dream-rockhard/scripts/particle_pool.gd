extends Node2D

func spawn_particles_at(pos: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var particle = _get_available_particle()
		if particle:
			var gradient = particle.color_ramp
			gradient.set_color(0, color)
			var transparent_color = color
			transparent_color.a = 0.0
			gradient.set_color(1, transparent_color)
			particle.global_position = pos
			particle.emitting = true

func put_particle_at(pos: Vector2) -> CPUParticles2D:
	var particle = _get_available_particle()
	if particle:
		particle.global_position = pos
	return particle


func _get_available_particle() -> CPUParticles2D:
	for child in get_children():
		if child is CPUParticles2D and not child.emitting:
			return child
	return null