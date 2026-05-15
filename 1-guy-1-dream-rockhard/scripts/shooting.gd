extends Node2D


var use_mouse := true

@export var muzzle_particles: Array[CPUParticles2D]
var _spawn_accumulator := 0.0
var sprite_offset_1: Vector2 = Vector2(0, 0)
var sprite_offset_2: Vector2 = Vector2(0, 0)
@onready var sprite = $Sprite2D
var prev_aim_direction: Vector2 = Vector2.ZERO

func _process(delta):
	var direction = get_aim_direction()
	prev_aim_direction = direction
	
	if direction != Vector2.ZERO:
		global_rotation = direction.angle()
		if direction.x > 0:
			sprite.flip_h = true
			sprite.offset = sprite_offset_2
			for particles in muzzle_particles:
				particles.rotation = 0
				particles.position.x = 260
		else:
			global_rotation += PI
			sprite.flip_h = false
			sprite.offset = sprite_offset_1
			for particles in muzzle_particles:
				particles.rotation = PI
				particles.position.x = -260
	else:
		if not Manager.auto_shoot:
			return

	_spawn_accumulator += World.main.particles_per_second * delta

	while _spawn_accumulator >= 1.0:
		_spawn_accumulator -= 1.0
		shoot(direction)


func get_aim_direction() -> Vector2:
	# if using mouse and mouse down
	if use_mouse and (Input.is_action_pressed("aim_mouse") or Manager.auto_shoot):
		return (get_global_mouse_position() - global_position).normalized()
	else:
		var input_vec = Vector2(
			Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
			Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		)
		
		return input_vec.normalized()


func shoot(base_direction: Vector2):
	if not World.the_guy.is_enabled():
		return
	var bullet = World.bullet_pool.get_bullet()
	# Choose the first shoot particle that is not currently emitting, or default to the first one if all are busy
	var shoot_particle
	for p in muzzle_particles:
		if not p.emitting:
			shoot_particle = p
			shoot_particle.emitting = true
			break
	bullet.global_position = global_position

	# Random angle within cone
	var base_angle = base_direction.angle()
	var angle_offset = randf_range(-World.main.width, World.main.width)
	var final_dir = Vector2.from_angle(base_angle + angle_offset)

	bullet.initialize(final_dir * World.main.particle_speed)

	Manager.audio.play_shoot_sfx()
	
	# animate recoil by briefly moving the sprite in the opposite direction
	var recoil_distance = 100.0
	var recoil_x = - final_dir.x * recoil_distance
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "position:x", recoil_x, 0.05)
	tween.tween_property(sprite, "position:x", 0.0, 0.1)
