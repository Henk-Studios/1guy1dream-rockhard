extends CharacterBody2D

var distance_traveled: float = 0.0
var dir: Vector2 = Vector2.ZERO

func initialize(direction: Vector2):
	dir = direction
	velocity = direction
	distance_traveled = 0.0

func _physics_process(delta):
	distance_traveled += velocity.length() * delta

	if distance_traveled > 2000:
		_return_to_pool()
		return

	var collision = move_and_collide(velocity * delta)

	if collision:
		# Bullet hit something → break if tile, then despawn or ricochet
		var collider = collision.get_collider()
		if collider is Tile:
			var main = World.terrain
			var exploded := false
			if World.main.bullet_explosive_chance_level > 0:
				var chance: float = World.main.bullet_explosive_chance_level * 0.01 / World.main.particles_per_second * 5
				if randf() < chance and main.has_method("bullet_explode"):
					main.bullet_explode(collider.cell, World.main.bullet_explosive_size_level)
					exploded = true
			if not exploded and main.has_method("break_cell"):
				main.break_cell(collider.cell, World.main.damage)
		
		if randf() < World.main.piercing:
			pass
		elif randf() < World.main.ricochet:
			velocity = velocity.rotated(PI + randf_range(-PI / 4, PI / 4))
		else:
			_return_to_pool()


func _return_to_pool():
	World.bullet_pool.return_bullet(self )
