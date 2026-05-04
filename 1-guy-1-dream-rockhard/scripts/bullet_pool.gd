extends Node2D
class_name BulletPool

@export var bullet_scene: PackedScene
var _available_bullets: Array[CharacterBody2D] = []
var _in_use_bullets: Array[CharacterBody2D] = []

func get_bullet() -> CharacterBody2D:
	var bullet: CharacterBody2D
	
	if _available_bullets.is_empty():
		# Create new bullet if pool is empty
		bullet = bullet_scene.instantiate()
	else:
		# Reuse bullet from pool
		bullet = _available_bullets.pop_back()
		bullet.show()
		bullet.velocity = Vector2.ZERO
		bullet.global_position = Vector2.ZERO
	
	_in_use_bullets.append(bullet)
	add_child(bullet)
	return bullet

func return_bullet(bullet: CharacterBody2D):
	if bullet in _in_use_bullets:
		_in_use_bullets.erase(bullet)
	
	bullet.hide()
	remove_child(bullet)
	_available_bullets.append(bullet)
