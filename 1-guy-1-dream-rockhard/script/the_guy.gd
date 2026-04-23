extends RigidBody2D

@export var thrust_force := 900.0
@export var torque_force := 900.0
@export var max_angular_velocity := 5.0


func _ready():
	self.linear_damp = 1.5
	self.angular_damp = 2.0

func _physics_process(delta):
	# Define fixed thrust directions
	var left_dir = Vector2(1, -1.5).normalized()   # up-left
	var right_dir = Vector2(-1, -1.5).normalized()   # up-right

	# LEFT JET
	if Input.is_action_pressed("leftjet"):
		apply_force(left_dir * thrust_force)
		apply_torque(-torque_force)

	# RIGHT JET
	if Input.is_action_pressed("rightjet"):
		apply_force(right_dir * thrust_force)
		apply_torque(torque_force)

	# Clamp rotation speed
	angular_velocity = clamp(angular_velocity, -max_angular_velocity, max_angular_velocity)
