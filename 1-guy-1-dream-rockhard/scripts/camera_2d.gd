extends Camera2D

const MOVE_SPEED := 1000.0
const ZOOM_STEP := 1.1
const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if dir != Vector2.ZERO:
		position += dir.normalized() * MOVE_SPEED * delta
		get_parent().update_region(global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom * ZOOM_STEP).clamp(Vector2.ONE * ZOOM_MIN, Vector2.ONE * ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom / ZOOM_STEP).clamp(Vector2.ONE * ZOOM_MIN, Vector2.ONE * ZOOM_MAX)
