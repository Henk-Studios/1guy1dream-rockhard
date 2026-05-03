extends CharacterBody2D

@export var timer: Timer
var prev_collision: Object = null
func _ready():
	if timer:
		timer.timeout.connect(_on_timer_timeout)

func initialize(direction: Vector2):
	velocity = direction

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)

	if collision:
		# Bullet hit something → break if tile, then despawn or ricochet
		var collider = collision.get_collider()
		if collider is Tile and collider != prev_collision:
			prev_collision = collider
			var main = Manager.scene.current_scene
			var exploded := false
			if Global.bullet_explosive_chance_level > 0:
				var chance: float = Global.bullet_explosive_chance_level * 0.01
				if randf() < chance and main.has_method("bullet_explode"):
					main.bullet_explode(collider.cell, Global.bullet_explosive_size_level)
					exploded = true
			if not exploded and main.has_method("break_cell"):
				main.break_cell(collider.cell, Global.damage)
		
		if randf() < Global.piercing:
			pass
		elif randf() < Global.ricochet:
			velocity = velocity.rotated(PI + randf_range(-PI / 4, PI / 4))
		else:
			queue_free()

func _on_timer_timeout():
	# Timer ran out → despawn
	queue_free()
