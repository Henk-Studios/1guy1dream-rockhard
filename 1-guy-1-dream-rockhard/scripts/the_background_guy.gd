extends Node2D

var initial_position: Vector2


func _ready() -> void:
	initial_position = position
	_setup_movement()
	_setup_rotation()


func _setup_movement() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:x", initial_position.x - 20, 2.0)
	tween.tween_property(self, "position:x", initial_position.x + 20, 2.0)
	tween.tween_property(self, "position:x", initial_position.x, 2.0)


func _setup_rotation() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation", PI / 4, 3.0)
	tween.tween_property(self, "rotation", -PI / 4, 3.0)
	tween.tween_property(self, "rotation", 0.0, 3.0)
