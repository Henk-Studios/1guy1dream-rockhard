extends Node2D
class_name RadialMenu
# Upgrades are: Bullet Speed, Bullet Damage, Bullet Rate, Bullet Spread, Bullet Penetration, Explosive Chance, Explosion Size, Vision Range, Jetpack Speed
var buttons: Array[WheelButtonConfig] = [
	# Magentas
	WheelButtonConfig.new("Pew Speed", _on_bullet_speed_pressed, Color.MAROON, 300, 30),
	WheelButtonConfig.new("Pew Damage", _on_bullet_damage_pressed, Color.MAROON, 1, 10),
	WheelButtonConfig.new("Pew Rate", _on_bullet_rate_pressed, Color.MAROON, 5, 50),
	# Oranges
	WheelButtonConfig.new("Pew Spread", _on_bullet_spread_pressed, Color.ORANGE, 0.1, 300, 31),
	WheelButtonConfig.new("Pierce Chance", _on_bullet_piercing_pressed, Color.ORANGE, 0, 500, 10),
	WheelButtonConfig.new("Ricochet Chance", _on_bullet_ricochet_pressed, Color.ORANGE, 0, 500, 10),
	# Reds
	WheelButtonConfig.new("Boom Chance", _on_explosive_chance_pressed, Color.INDIAN_RED, 0, 5000),
	WheelButtonConfig.new("Boom Size", _on_explosion_size_pressed, Color.INDIAN_RED, 0, 6000),
	# blues
	WheelButtonConfig.new("Vision Range", _on_vision_range_pressed, Color.TEAL, 0.3, 100, 8),
	WheelButtonConfig.new("Jetpack Speed", _on_jetpack_speed_pressed, Color.TEAL, 700, 50),
]
@export var button_scene: PackedScene
var selected_index := -1
var outer_radius: float = 100.0
var inner_radius: float = 50.0
var spacing: float = 8.0
var shop_open := false
var button_instances: Array[WheelButton] = []
func _ready() -> void:
	hide()
	# Create buttons based on the configuration
	for i in range(buttons.size()):
		var button_config = buttons[i]
		var button = button_scene.instantiate() as WheelButton
		add_child(button)
		button.setup_button(button_config, buttons.size(), i, inner_radius, outer_radius, spacing)
		button.button_pressed.connect(_on_button_pressed.bind(button_config.action, i))
		button_instances.append(button)

func _on_button_pressed(action: Callable, index: int) -> void:
	Manager.audio.play_click_sfx()
	var old_price = button_instances[index].price
	if Global.money < old_price or button_instances[index].level >= buttons[index].max_lvl:
		return
	Global.money -= old_price
	button_instances[index].update_level()
	var new_price: int = action.call(old_price)
	button_instances[index].update_price(new_price)

# Seperate functions to allow for more complex upgrade logic if ever needed

func _on_bullet_speed_pressed(p) -> int:
	Global.particle_speed += 50
	return increase_price(p, 0, 1.5)

func _on_bullet_damage_pressed(p) -> int:
	Global.damage += 1
	return increase_price(p, 30, 1.05)

func _on_bullet_rate_pressed(p) -> int:
	Global.particles_per_second += 1
	return increase_price(p, 20, 1.1)

func _on_bullet_spread_pressed(p) -> int:
	Global.width += 0.1
	return increase_price(p, 100, 2)

func _on_bullet_piercing_pressed(p) -> int:
	Global.piercing += 0.1
	return increase_price(p, 300, 1.5)

func _on_bullet_ricochet_pressed(p) -> int:
	Global.ricochet += 0.1
	return increase_price(p, 300, 1.5)

func _on_explosive_chance_pressed(p) -> int:
	Global.bullet_explosive_chance_level += 1
	return increase_price(p, 1000, 1.2)

func _on_explosion_size_pressed(p) -> int:
	Global.bullet_explosive_size_level += 1
	return increase_price(p, 750, 1.2)

func _on_vision_range_pressed(p) -> int:
	Global.vision += 0.1
	Manager.scene.current_scene.apply_resolution_zoom()
	return increase_price(p, 50, 1.2)

func _on_jetpack_speed_pressed(p) -> int:
	Global.jetpackspeed += 100
	return increase_price(p, 5, 1.4)

func increase_price(old_price: int, add: int, mult: float) -> int:
	var new_price: int = int(old_price * mult + add)
	return new_price
	

func toggle_shop() -> void:
	if shop_open:
		close_shop()
	else:
		open_shop()

func open_shop() -> void:
	shop_open = true
	Global.shop_open = true
	show()

func close_shop() -> void:
	shop_open = false
	Global.shop_open = false
	hide()

func _input(event) -> void:
	if event.is_action_pressed("buy") and shop_open:
		buy_selected()

func _process(__) -> void:
	if Input.is_action_pressed("shop") and not shop_open:
		open_shop()
	elif not Input.is_action_pressed("shop") and shop_open:
		close_shop()
	if not shop_open:
		return
		
	handle_joystick_selection()

func handle_joystick_selection() -> void:
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input_vector.length() < 0.2:
		if selected_index != -1:
			set_selected(-1)
		return

	input_vector = input_vector.normalized()
	var angle = atan2(input_vector.y, input_vector.x)
	if angle < 0:
		angle += TAU
	var num_buttons = buttons.size()
	var angle_per_button = TAU / num_buttons
	var best_index = int(floor((angle + angle_per_button / 2) / angle_per_button)) % num_buttons
	if best_index != selected_index:
		set_selected(best_index)

func set_selected(index: int) -> void:
	selected_index = index
	for i in range(button_instances.size()):
		var button = button_instances[i]
		if i == index:
			button.select()
		else:
			button.deselect()

func buy_selected() -> void:
	if selected_index == -1:
		return
	
	var button = button_instances[selected_index]
	button.pressed()
	await get_tree().create_timer(0.1).timeout
	if button.is_selected:
		button.set_highlight_appearance()
