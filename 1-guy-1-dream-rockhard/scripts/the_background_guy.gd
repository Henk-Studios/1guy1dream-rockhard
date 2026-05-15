extends Node2D
class_name TheBackgroundGuy

@onready var sprite = $Sprite2D

@export var speed: float = 0.5 # Determines how fast `t` progresses through the curve
var points: Array[Vector2] = []
var t: float = 0.0
var time_passed: float = 0.0

func _ready() -> void:
	# Initialize with 4 points for the B-spline math
	for i in range(4):
		points.append(_get_random_border_point())
	
	# Start character at the beginning of the curve
	position = _get_bspline_point(points[0], points[1], points[2], points[3], 0.0)

func _process(delta: float) -> void:
	time_passed += delta
	# Advance through the curve
	t += speed * delta
	
	# Move to the next segment when t reaches 1.0 (end of current curve section)
	while t >= 1.0:
		t -= 1.0
		points.pop_front()
		points.append(_get_random_border_point())
	
	var next_pos = _get_bspline_point(points[0], points[1], points[2], points[3], t)
	
	# Rotate the sprite around an average of 33 degrees with some pseudo-random smooth wobble
	if sprite:
		sprite.rotation_degrees = 33.0 + sin(time_passed * 2.5) * 10.0 + cos(time_passed * 1.7) * 8.0
	else:
		rotation_degrees = 33.0 + sin(time_passed * 2.5) * 10.0 + cos(time_passed * 1.7) * 8.0
		
	position = next_pos

func _get_random_border_point() -> Vector2:
	# Gets a valid random point along the extremely outer edge (border) of the screen
	var screen_size = get_viewport_rect().size
	var w = screen_size.x
	var h = screen_size.y
	var perimeter = (w + h) * 2.0
	var r = randf() * perimeter
	
	if r < w:
		return Vector2(r, 0) # Top edge
	r -= w
	if r < h:
		return Vector2(w, r) # Right edge
	r -= h
	if r < w:
		return Vector2(w - r, h) # Bottom edge
	r -= w
	return Vector2(0, h - r) # Left edge

func _get_bspline_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, progress: float) -> Vector2:
	# Uniform Cubic B-Spline interpolation
	# Provides a path strictly contained within the points' convex hull, 
	# approaching them nicely without actually hitting them, ensuring C2 continuous smooth curves
	var it = 1.0 - progress
	var w0 = (it * it * it) / 6.0
	var w1 = (3.0 * progress * progress * progress - 6.0 * progress * progress + 4.0) / 6.0
	var w2 = (-3.0 * progress * progress * progress + 3.0 * progress * progress + 3.0 * progress + 1.0) / 6.0
	var w3 = (progress * progress * progress) / 6.0
	
	return p0 * w0 + p1 * w1 + p2 * w2 + p3 * w3
