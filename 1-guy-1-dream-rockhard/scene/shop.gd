extends Control

@export var button_scene: PackedScene
@export var radius := 200.0
@export var options_to_show := 5

var buttons: Array = []
var shop_open := false

var selected_index := -1

var upgrades := {
	"jetpack_speed": {
		"name": "Jetpack Speed",
		"target": "jetpackspeed",
		"value": 700,
		"increase": 100,
		"price": 50,
		"price_add": 5,
		"price_mult": 2
	},
	"bulletspeed": {
		"name": "Bullet Speed",
		"target": "bulletspeed",
		"value": 10.0,
		"increase": 1,
		"price": 30,
		"price_add": 10,
		"price_mult": 1.1
	}
}

func _input(event):
	if event.is_action_pressed("shop"):
		toggle_shop()
	if event.is_action_pressed("buy") and shop_open:
		buy_selected()
		
func _process(delta):
	if not shop_open:
		return
		
	

	handle_joystick_selection()

func toggle_shop():
	if shop_open:
		close_shop()
	else:
		open_shop()

func open_shop():
	shop_open = true
	create_button_circle()

func close_shop():
	shop_open = false
	for b in buttons:
		b.queue_free()
	buttons.clear()

func create_button_circle():
	var center = size / 2
	var start_angle := -PI / 2

	var keys = upgrades.keys()
	var amount = min(options_to_show, keys.size())

	# optional: shuffle so shop feels random each time
	keys.shuffle()

	for i in range(amount):
		var key = keys[i]
		var upgrade = upgrades[key]

		var angle = start_angle + (TAU / amount) * i
		var pos = center + Vector2.RIGHT.rotated(angle) * radius

		var button = button_scene.instantiate()
		add_child(button)

		button.position = pos - button.size / 2
		button.upgrade_key = key

		update_button_text(button)

		buttons.append(button)
		
func update_button_text(button):
	var u = upgrades[button.upgrade_key]

	var current = u["value"]
	var next = current + u["increase"]
	var price = u["price"]

	button.text = "%s\n$%d\n%d -> %d" % [
		u["name"],
		price,
		current,
		next
	]

func handle_joystick_selection():
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input_vector.length() < 0.2:
		return

	input_vector = input_vector.normalized()

	var center = size / 2
	var best_index := -1
	var best_score := -INF

	for i in range(buttons.size()):
		var button = buttons[i]

		# direction from center to button
		var dir = (button.position + button.size / 2 - center).normalized()

		var score = input_vector.dot(dir)

		if score > best_score:
			best_score = score
			best_index = i

	set_selected(best_index)
	
func set_selected(index: int):
	if index == selected_index:
		return

	selected_index = index

	for i in range(buttons.size()):
		var b = buttons[i]

		if i == selected_index:
			b.grab_focus()
			b.scale = Vector2.ONE * 1.2
		else:
			b.scale = Vector2.ONE

func buy_selected():
	if selected_index < 0 or selected_index >= buttons.size():
		return

	var button = buttons[selected_index]
	var key = button.upgrade_key
	var u = upgrades[key]

	print("Bought:", u["name"])

	# APPLY UPGRADE VALUE
	u["value"] += u["increase"]

	# APPLY TO GLOBAL VARIABLE (GENERIC)
	var target = u["target"]
	if global.has_method("set"):
		global.set(target, u["value"])
	else:
		global.set(target, u["value"])

	# PRICE SCALING
	u["price"] = int(u["price"] * u["price_mult"] + u["price_add"])

	# refresh UI text
	update_button_text(button)

	
