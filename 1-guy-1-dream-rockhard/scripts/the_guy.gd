extends RigidBody2D
class_name TheGuy

@export var thrust_force := 900.0
@export var torque_force := 900.0
@export var max_angular_velocity := 5.0
@export var physics_material: PhysicsMaterial
@onready var fire_particles: CPUParticles2D = $FireParticles
var was_jetting: bool = false
var credits_reached: bool = false
var _enabled: bool = false
@onready var jetpart: CPUParticles2D = $jetpart
func _ready():
	self.linear_damp = 1
	self.angular_damp = 2.0

func freeze_guy() -> void:
	_enabled = false
	freeze = true

func enable() -> void:
	freeze = false
	_enabled = true

func is_enabled() -> bool:
	return _enabled

func _physics_process(__):
	if Input.is_action_just_pressed("teleport") and Manager.dev_mode:
		global_position.y = -30
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
	
	if position.y < -World.terrain.world_thickness * World.terrain.TILE_SIZE and not credits_reached:
		World.credits.start_credits()
		credits_reached = true
	
	# Define fixed thrust directions
	var left_dir = Vector2(1, -1.5).normalized() # up-left
	var right_dir = Vector2(-1, -1.5).normalized() # up-right
	var left_pressed = Input.is_action_pressed("leftjet")
	var right_pressed = Input.is_action_pressed("rightjet")
	
	# Handle follow_mouse mode
	if Manager.follow_mouse:
		var mouse_pos = get_global_mouse_position()
		var relative_pos = mouse_pos - global_position
		
		# Only respond if mouse is above the guy
		if relative_pos.y < 20:
			var threshold = 50.0
			if relative_pos.x < -threshold:
				# Mouse to upper-left
				left_pressed = false
				right_pressed = true
			elif relative_pos.x > threshold:
				# Mouse to upper-right
				right_pressed = false
				left_pressed = true
			else:
				# Mouse directly above
				left_pressed = true
				right_pressed = true
		else:
			# Mouse below, don't fire
			left_pressed = false
			right_pressed = false

	if _enabled:
		# LEFT JET
		if left_pressed:
			apply_force(left_dir * World.main.jetpackspeed)
			apply_torque(-torque_force)

		# RIGHT JET
		if right_pressed:
			apply_force(right_dir * World.main.jetpackspeed)
			apply_torque(torque_force)
		
	var jetting: bool = right_pressed or left_pressed
	if jetting and not was_jetting:
		$jetpart.emitting = true
		Manager.audio.start_jetfart_sfx("1")
		was_jetting = true
	elif not jetting and was_jetting:
		$jetpart.emitting = false
		Manager.audio.stop_jetfart_sfx("1")
		was_jetting = false

	if left_pressed and right_pressed:
		physics_material.bounce = 0.2
	elif left_pressed or right_pressed:
		physics_material.bounce = 0.7
	else:
		physics_material.bounce = 0.3

	# Clamp rotation speed
	angular_velocity = clamp(angular_velocity, -max_angular_velocity, max_angular_velocity)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		var collision_speed = state.get_linear_velocity().length()
		if collision_speed > 40:
			# Check if collision is perpendicular to surface (not sliding)
			var velocity_dir = state.get_linear_velocity().normalized()
			for i in range(state.get_contact_count()):
				var contact_normal = state.get_contact_local_normal(i)
				
				# Dot product: 1 = perpendicular, 0 = parallel/sliding
				var dot_product = abs(velocity_dir.dot(contact_normal))
				
				if dot_product > 0.5: # Adjust threshold (higher = more perpendicular)
					# Deal damage to tiles based on collision speed
					var damage = maxi(1, int(collision_speed / 80)) * World.main.jetpackspeed / 700
					World.terrain.break_cell_at_world_pos(state.get_contact_collider_object(i).position, damage)
