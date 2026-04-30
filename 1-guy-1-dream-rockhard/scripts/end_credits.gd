extends Control
@export var guy: TheGuy
@onready var time_label: RichTextLabel = $VBoxContainer/TimeLabel

func _process(delta: float) -> void:
	# smoothly follow the guy (x pos only), but with a slight delay for a more dynamic feel
	var target_x = guy.position.x
	position.x = lerp(position.x, target_x, 0.05)
