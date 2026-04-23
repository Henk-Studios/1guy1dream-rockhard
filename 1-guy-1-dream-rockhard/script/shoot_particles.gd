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
		# Bullet hit something → break if tile, then despawn
		var collider = collision.get_collider()
		if collider is Tile:
			var main = get_tree().current_scene
			if main.has_method("break_cell"):
				main.break_cell(collider.cell, 1)
		queue_free()

func _on_timer_timeout():
	# Timer ran out → despawn
	queue_free()
