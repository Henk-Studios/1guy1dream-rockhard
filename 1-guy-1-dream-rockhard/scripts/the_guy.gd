extends RigidBody2D

@export var thrust_force := 900.0
@export var torque_force := 900.0
@export var max_angular_velocity := 5.0

var _jetpack_audio: AudioStreamPlayer


func _ready():
	self.linear_damp = 1.5
	self.angular_damp = 2.0
	_jetpack_audio = AudioStreamPlayer.new()
	_jetpack_audio.process_mode = Node.PROCESS_MODE_ALWAYS  # lets us stop it even when the tree is paused
	var stream = load("res://audio/jetfart.mp3")
	if stream is AudioStreamMP3:
		stream.loop = true
	_jetpack_audio.stream = stream
	add_child(_jetpack_audio)
	if Global.has_signal("credits"):
		Global.credits.connect(_on_credits)

func _on_credits() -> void:
	if is_instance_valid(_jetpack_audio):
		_jetpack_audio.stop()
		_jetpack_audio.stream_paused = true
		_jetpack_audio.stream = null



func _physics_process(delta):
	if Input.is_action_just_pressed("teleport"):
		position.y = -30
	
	if position.y < -40 and not Global.creditsreached:
		Global.creditsreached = true
		Global.credits.emit()
	
	# Define fixed thrust directions
	var left_dir = Vector2(1, -1.5).normalized() # up-left
	var right_dir = Vector2(-1, -1.5).normalized() # up-right

	# LEFT JET
	if Input.is_action_pressed("leftjet"):
		apply_force(left_dir * Global.jetpackspeed)
		apply_torque(-torque_force)

	# RIGHT JET
	if Input.is_action_pressed("rightjet"):
		apply_force(right_dir * Global.jetpackspeed)
		apply_torque(torque_force)
		
	var jetting: bool = Input.is_action_pressed("rightjet") or Input.is_action_pressed("leftjet")
	if jetting and not Global.creditsreached:
		$jetpart.emitting = true
		if _jetpack_audio and not _jetpack_audio.playing:
			_jetpack_audio.play()
	else:
		$jetpart.emitting = false
		if _jetpack_audio and _jetpack_audio.playing:
			_jetpack_audio.stop()
		
	# Clamp rotation speed
	angular_velocity = clamp(angular_velocity, -max_angular_velocity, max_angular_velocity)
