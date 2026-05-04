extends Camera2D

const MOVE_SPEED := 1000.0
const ZOOM_STEP := 1.1
const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0
const CAMERA_FOLLOW_SPEED := 5.0
const CAMERA_MAX_DISTANCE := 50.0
var free_cam_enabled: bool = false

func setup() -> void:
	position = World.the_guy.position
	apply_resolution_zoom()
	get_viewport().size_changed.connect(apply_resolution_zoom)

func _process(delta: float) -> void:
	if free_cam_enabled:
		var dir := Vector2.ZERO
		if Input.is_key_pressed(KEY_UP):
			dir.y -= 1
		if Input.is_key_pressed(KEY_DOWN):
			dir.y += 1
		if Input.is_key_pressed(KEY_LEFT):
			dir.x -= 1
		if Input.is_key_pressed(KEY_RIGHT):
			dir.x += 1
		if dir != Vector2.ZERO:
			position += dir.normalized() * MOVE_SPEED * delta
			World.terrain.update_region(global_position)
	else:
		# Smoothly follow the player with max distance constraint
		var target_pos = World.the_guy.position
		var distance_to_player = position.distance_to(target_pos)
		
		# Smoothly accelerate follow speed based on how far we are from the player
		var excess_distance = maxf(distance_to_player - CAMERA_MAX_DISTANCE, 0.0)
		var speed_multiplier = 1.0 + (excess_distance / CAMERA_MAX_DISTANCE) * 3.0
		var follow_speed = CAMERA_FOLLOW_SPEED * speed_multiplier
		
		# Clamp lerp parameter to prevent NaN from huge teleports
		var lerp_t = minf(follow_speed * delta, 1.0)
		position = position.lerp(target_pos, lerp_t)

		# backup snap if teleporting or something causes us to get really far away
		if position.distance_to(target_pos) > CAMERA_MAX_DISTANCE * 2:
			position.move_toward(World.the_guy.position, CAMERA_MAX_DISTANCE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and free_cam_enabled:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = (zoom * ZOOM_STEP).clamp(Vector2.ONE * ZOOM_MIN, Vector2.ONE * ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = (zoom / ZOOM_STEP).clamp(Vector2.ONE * ZOOM_MIN, Vector2.ONE * ZOOM_MAX)

func toggle_free_cam() -> void:
	free_cam_enabled = not free_cam_enabled


# Zoom scales with window width so every monitor shows the same slice of the world.
# REFERENCE_WIDTH is the resolution the game was tuned at; BASE_ZOOM is the zoom at that size.
const REFERENCE_WIDTH := 1152.0
const BASE_ZOOM := .9

func apply_resolution_zoom() -> void:
	var w: float = get_viewport_rect().size.x
	var factor: float = maxf(w / REFERENCE_WIDTH, 0.1)
	var z := Vector2(BASE_ZOOM * factor, BASE_ZOOM * factor) / Global.vision
	zoom = z
