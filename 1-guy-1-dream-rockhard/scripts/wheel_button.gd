extends Node2D
class_name WheelButton
## A button that can be used in a radial menu.
@onready var outline: Polygon2D = $OutlinePolygon2D
@onready var polygon: Polygon2D = $OutlinePolygon2D/Polygon2D
@onready var area: Area2D = $OutlinePolygon2D/Polygon2D/Area2D
@onready var collider: CollisionPolygon2D = $OutlinePolygon2D/Polygon2D/Area2D/CollisionPolygon2D
@onready var info: Control = $Control
@onready var title_label: RichTextLabel = $Control/VBoxContainer/TitleLabel
@onready var price_label: RichTextLabel = $Control/VBoxContainer/PriceLabel
@onready var info_label: RichTextLabel = $Control/VBoxContainer/InfoLabel

var color: Color = Color(1, 1, 1, 1)
var outline_width = 1.8
var level: int = 0
signal button_pressed
var upgrade_name: String = "Unknown Upgrade"
var is_hovered: bool = false
var is_selected: bool = false
var center_offset: Vector2 = Vector2(-80, -80) # Adjust as needed to center the title_label properly
var info_distance_correction: float = 1.1
var default_scale: Vector2 = Vector2(1, 1)
var prev_mouse_pos: Vector2 = Vector2.ZERO
var price: int = 0
var max_level: int = 999

func _ready() -> void:
	# Example setup: 4 buttons in a menu, this is button index 0, with inner radius 100 and outer radius 200
	polygon.material.set_shader_parameter("mix_color", color)
	default_scale = self.scale
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)
	World.main.money_changed.connect(_on_money_changed)
	update_level()

func _on_mouse_entered() -> void:
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.distance_to(prev_mouse_pos) < 1:
		return # Ignore if mouse hasn't moved much to prevent flickering when hovering near edges
	prev_mouse_pos = mouse_pos
	hover()

func hover() -> void:
	Manager.audio.play_hover_sfx()
	is_hovered = true
	set_highlight_appearance()

func set_highlight_appearance() -> void:
	scale = default_scale * 1.05
	# polygon.material.set_shader_parameter("mix_color", color.lightened(0.3))
func set_selected_appearance() -> void:
	scale = default_scale * 1.1
	# polygon.material.set_shader_parameter("mix_color", color.lightened(0.6))
func set_default_appearance() -> void:
	scale = default_scale
	# polygon.material.set_shader_parameter("mix_color", color)
func _on_mouse_exited() -> void:
	is_hovered = false
	set_default_appearance()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed()
		elif is_hovered:
			set_highlight_appearance()
		else:
			set_default_appearance()

func select():
	is_selected = true
	hover()

func deselect():
	is_selected = false
	_on_mouse_exited()

func pressed():
	set_selected_appearance()
	emit_signal("button_pressed")


## Generates the button shape as a wedge segment of an annulus (ring).
## The shape is two concentric arcs connected by two radial lines.
func generate_button_shape(
	num_buttons: int,
	button_index: int,
	radius_inner: float,
	radius_outer: float,
	arc_segments: int = 32,
	spacing: float = 0.0
) -> PackedVector2Array:
	var angle_per_button = TAU / num_buttons
	var start_angle = angle_per_button * button_index - angle_per_button / 2.0
	var end_angle = start_angle + angle_per_button
	var main_angle = (start_angle + end_angle) / 2.0
	var points = PackedVector2Array()
	
	# Generate outer arc (from start_angle to end_angle)
	for i in range(arc_segments + 1):
		var t = float(i) / arc_segments
		var angle = lerp(start_angle, end_angle, t)
		points.append(Vector2(cos(angle), sin(angle)) * radius_outer + Vector2(cos(main_angle), sin(main_angle)) * spacing)
	
	# Generate inner arc (from end_angle to start_angle, going backwards)
	# This closes the shape with the inner arc
	for i in range(arc_segments, -1, -1):
		var t = float(i) / arc_segments
		var angle = lerp(start_angle, end_angle, t)
		points.append(Vector2(cos(angle), sin(angle)) * radius_inner + Vector2(cos(main_angle), sin(main_angle)) * spacing)

	# Set info position
	info.position = Vector2(cos(main_angle), sin(main_angle)) * (radius_inner + radius_outer) / 2.0 * info_distance_correction + center_offset
	
	return points


## Generates an outline polygon that traces the perimeter of the button.
func generate_button_outline(
	num_buttons: int,
	button_index: int,
	radius_inner: float,
	radius_outer: float,
	outline_w: float = 2.0,
	arc_segments: int = 32,
	spacing: float = 0.0
) -> PackedVector2Array:
	var angle_per_button = TAU / num_buttons
	var start_angle = angle_per_button * button_index - angle_per_button / 2.0
	var end_angle = start_angle + angle_per_button
	var main_angle = (start_angle + end_angle) / 2.0
	var spacing_offset = Vector2(cos(main_angle), sin(main_angle)) * spacing
	
	var expanded_outer = radius_outer + outline_w
	var expanded_inner = radius_inner - outline_w
	var points = PackedVector2Array()
	
	# Perpendicular offsets for radial edges (tangential direction)
	var start_perp = Vector2(cos(start_angle - PI / 2.0), sin(start_angle - PI / 2.0)) * outline_w
	var end_perp = Vector2(cos(end_angle + PI / 2.0), sin(end_angle + PI / 2.0)) * outline_w
	
	# Outer expanded arc (from start_angle to end_angle) - skip i=0 to avoid duplicate
	for i in range(1, arc_segments + 1):
		var t = float(i) / arc_segments
		var angle = lerp(start_angle, end_angle, t)
		points.append(Vector2(cos(angle), sin(angle)) * expanded_outer + spacing_offset)
	
	# Outer radial edge at end_angle with thickness
	points.append(Vector2(cos(end_angle), sin(end_angle)) * expanded_outer + end_perp + spacing_offset)
	
	# Inner arc at end_angle with thickness
	points.append(Vector2(cos(end_angle), sin(end_angle)) * expanded_inner + end_perp + spacing_offset)
	
	# Inner expanded arc (from end_angle to start_angle, backwards) - skip endpoints to avoid duplicates with radial edges
	for i in range(arc_segments - 1, 0, -1):
		var t = float(i) / arc_segments
		var angle = lerp(start_angle, end_angle, t)
		points.append(Vector2(cos(angle), sin(angle)) * expanded_inner + spacing_offset)
	
	# Inner radial edge at start_angle with thickness
	points.append(Vector2(cos(start_angle), sin(start_angle)) * expanded_inner + start_perp + spacing_offset)
	
	# Outer arc at start_angle with thickness
	points.append(Vector2(cos(start_angle), sin(start_angle)) * expanded_outer + start_perp + spacing_offset)
	
	return points


## Sets up the button's polygon shape and creates a collision polygon.
func setup_button(config: WheelButtonConfig, num_buttons: int, button_index: int, radius_inner: float, radius_outer: float, spacing: float = 0.0) -> void:
	var shape_points = generate_button_shape(num_buttons, button_index, radius_inner, radius_outer, 32, spacing)
	polygon.polygon = shape_points
	collider.polygon = shape_points
	
	# Create outline with proper perimeter tracing
	
	var outline_points = generate_button_outline(
		num_buttons,
		button_index,
		radius_inner,
		radius_outer,
		outline_width,
		32,
		spacing
	)
	upgrade_name = config.title
	outline.polygon = outline_points
	color = config.color
	max_level = config.max_lvl
	polygon.material.set_shader_parameter("mix_color", color)
	update_price(config.start_price)
	set_affordability(World.main.money >= price)

	# Set info
	title_label.text = config.title

func update_price(cost: int) -> void:
	if price_label.text == "MAX":
		return # Don't update price if already at max
	price = cost
	price_label.text = "$%d" % cost

func update_level() -> void:
	level += 1
	if level == max_level:
		info_label.text = "MAX Level (%d)" % level
		price_label.text = "MAX"
	else:
		info_label.text = "Level %d" % level

func set_affordability(can_afford: bool) -> void:
	if can_afford:
		price_label.modulate = Color(1, 1, 1, 1)
	else:
		price_label.modulate = Color(1, 0.0, 0.0, 1)

func _on_money_changed(__) -> void:
	set_affordability(World.main.money >= price)


func apply_state(p_level: int, p_price: int) -> void:
	# Apply saved level and next-upgrade price without triggering side-effects
	level = p_level
	if level >= max_level:
		info_label.text = "MAX Level (%d)" % level
		price_label.text = "MAX"
		price = 0
	else:
		info_label.text = "Level %d" % level
		price = int(p_price)
		price_label.text = "$%d" % price
	set_affordability(World.main.money >= price)
