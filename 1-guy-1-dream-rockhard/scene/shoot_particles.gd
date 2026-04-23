extends CharacterBody2D

@export var timer: Timer

func _ready():
	if timer:
		timer.timeout.connect(_on_timer_timeout)

func initialize(direction: Vector2):
	velocity = direction

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		# Bullet hit something → despawn
		queue_free()

func _on_timer_timeout():
	# Timer ran out → despawn
	queue_free()