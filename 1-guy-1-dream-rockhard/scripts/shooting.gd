extends Node2D



var use_mouse := true

@export var particle_scene: PackedScene

var _spawn_accumulator := 0.0

func _process(delta):
	var direction = get_aim_direction()
	rotation = direction.angle()
	# $Sprite2D.flip_v = direction.x > 0
	if direction == Vector2.ZERO:
		return

	_spawn_accumulator += global.particles_per_second * delta

	while _spawn_accumulator >= 1.0:
		_spawn_accumulator -= 1.0
		spawn_particle(direction)


func get_aim_direction() -> Vector2:
	# if using mouse and mouse down
	if use_mouse and Input.is_action_pressed("aim_mouse"):
		return (get_global_mouse_position() - global_position).normalized()
	else:
		var input_vec = Vector2(
			Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
			Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		)
		print(input_vec)
		return input_vec.normalized()


func spawn_particle(base_direction: Vector2):
	var particle = particle_scene.instantiate()
	get_tree().current_scene.add_child(particle)

	particle.global_position = global_position

	# Random angle within cone
	var base_angle = base_direction.angle()
	var angle_offset = randf_range(-global.width, global.width)
	var final_dir = Vector2.from_angle(base_angle + angle_offset)

	particle.initialize(final_dir * global.particle_speed)
