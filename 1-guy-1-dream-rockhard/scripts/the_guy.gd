extends RigidBody2D
class_name TheGuy

@export var thrust_force := 900.0
@export var torque_force := 900.0
@export var max_angular_velocity := 5.0
@export var physics_material: PhysicsMaterial
var was_jetting: bool = false
var credits_reached: bool = false
@onready var jetpart: CPUParticles2D = $jetpart
func _ready():
	self.linear_damp = 1
	self.angular_damp = 2.0

func _physics_process(__):
	if Input.is_action_just_pressed("teleport") and World.main.dev_mode:
		global_position.y = -30
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
	
	if position.y < 0 and not credits_reached:
		World.credits.start_credits()
		credits_reached = true
	
	# Define fixed thrust directions
	var left_dir = Vector2(1, -1.5).normalized() # up-left
	var right_dir = Vector2(-1, -1.5).normalized() # up-right
	var left_pressed = Input.is_action_pressed("leftjet")
	var right_pressed = Input.is_action_pressed("rightjet")

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
