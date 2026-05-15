extends Control
class_name Credits
@export var guy: TheGuy
@onready var time_label: RichTextLabel = $VBoxContainer/TimeLabel
var disabled: bool = false

func _process(__) -> void:
	# smoothly follow the guy (x pos only), but with a slight delay for a more dynamic feel
	var target_x = guy.position.x
	position.x = lerp(position.x, target_x, 0.05)

func disable() -> void:
	visible = false
	disabled = true
func start_credits() -> void:
	if disabled:
		return
	# Update personal record if this run is better
	var current_time = World.main.time_elapsed
	World.main.time_frozen = true
	var game_type = World.main.gamemode
	var seed_type = World.main.seed_type_used
	
	time_label.text = "[color=blue]Time: %s[/color]" % Manager.utility.format_time(current_time)
	var current_record: float = Manager.utility.get_personal_record(game_type, seed_type)
	
	# For normal and infinite modes: lower time is better
	var is_new_record = current_time < current_record
	
	if is_new_record:
		Manager.utility.set_personal_record(current_time, game_type, seed_type)
		time_label.text += " [color=deep_pink][wave](New Record!)[/wave][/color]"
	else:
		if current_record != INF:
			time_label.text += " (PR: %s)" % Manager.utility.format_time(current_record)
	
	await Manager.audio.play_credit_music()
	Manager.audio.play_main_music()
