extends Button
var upgrade_key
var nr

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed():
	print("shop button pressed")
	var shop = get_parent()
	if shop and shop.has_method("buy_from_button"):
		shop.buy_from_button(nr)
