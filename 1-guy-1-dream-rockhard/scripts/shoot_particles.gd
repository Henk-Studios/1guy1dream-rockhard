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
		print("Bullet collided with: " + str(collision.get_collider()))
		# Bullet hit something → break if tile, then despawn
		var collider = collision.get_collider()
		if collider is Tile:
			print("Bullet hit a tile at cell: " + str(collider.cell))
			var main = Manager.scene.current_scene
			print("main: " + str(main))
			var exploded := false
			if Global.bullet_explosive_chance_level > 0:
				var chance: float = Global.bullet_explosive_chance_level * 0.01
				if randf() < chance and main.has_method("bullet_explode"):
					main.bullet_explode(collider.cell, Global.bullet_explosive_size_level)
					exploded = true
			if not exploded and main.has_method("break_cell"):
				print("Bullet breaking cell at: " + str(collider.cell) + " with damage: " + str(Global.damage))
				main.break_cell(collider.cell, Global.damage)
			else:
				print("has method break_cell: " + str(main.has_method("break_cell")))
		queue_free()

func _on_timer_timeout():
	# Timer ran out → despawn
	queue_free()
