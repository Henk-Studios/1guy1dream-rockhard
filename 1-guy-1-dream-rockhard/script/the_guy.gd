extends RigidBody2D

@export var thrust_force := 900.0
@export var torque_force := 900.0
@export var max_angular_velocity := 5.0
@export var audio_player: Node

func _ready():
	self.linear_damp = 1.5
	self.angular_damp = 2.0



func _physics_process(delta):
	if Input.is_action_just_pressed("teleport"):
		position.y = -30
	
	if position.y < -40 and not Global.creditsreached:
		Global.creditsreached = true
		Global.credits.emit()
	
	# Define fixed thrust directions
	var left_dir = Vector2(1, -1.5).normalized() # up-left
	var right_dir = Vector2(-1, -1.5).normalized() # up-right

	var jetting = false
	# LEFT JET
	if Input.is_action_pressed("leftjet"):
		apply_force(left_dir * Global.jetpackspeed)
		apply_torque(-torque_force)
		audio_player.start_looping_sfx("jetfart")
		jetting = true

	# RIGHT JET
	if Input.is_action_pressed("rightjet"):
		apply_force(right_dir * Global.jetpackspeed)
		apply_torque(torque_force)

	# Clamp rotation speed
	angular_velocity = clamp(angular_velocity, -max_angular_velocity, max_angular_velocity)
