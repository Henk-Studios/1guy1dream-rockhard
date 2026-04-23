extends RigidBody2D

@export var thrust_force := 600.0
@export var torque_force := 1200.0
@export var max_angular_velocity := 4.0

@export var stabilize_force := 200.0



func _ready():
	self.linear_damp = linear_damp
	self.angular_damp = angular_damp

func _physics_process(delta):
	var thrust_dir = -transform.y  # local "up"

	# --- STABILIZING LIFT ---
	var upright_factor = clamp(Vector2.UP.dot(thrust_dir), 0.0, 1.0)
	apply_force(thrust_dir * stabilize_force * upright_factor)

	# LEFT JET
	if Input.is_action_pressed("rightjet"):
		apply_force(thrust_dir * thrust_force)
		apply_torque(-torque_force)

	# RIGHT JET
	if Input.is_action_pressed("leftjet"):
		apply_force(thrust_dir * thrust_force)
		apply_torque(torque_force)

	# Clamp spin so it doesn't go crazy
	angular_velocity = clamp(angular_velocity, -max_angular_velocity, max_angular_velocity)
