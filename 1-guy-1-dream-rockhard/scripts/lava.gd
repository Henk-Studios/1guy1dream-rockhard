extends Polygon2D
class_name Lava
func _process(__) -> void:
	# follow the guy's x position
	position.x = World.camera.position.x
