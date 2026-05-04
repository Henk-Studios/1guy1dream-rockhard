extends Control
class_name Credits
@export var guy: TheGuy
@onready var time_label: RichTextLabel = $VBoxContainer/TimeLabel

func _process(__) -> void:
	# smoothly follow the guy (x pos only), but with a slight delay for a more dynamic feel
	var target_x = guy.position.x
	position.x = lerp(position.x, target_x, 0.05)

func start_credits() -> void:
	# Update personal record if this run is better
	time_label.text = "[color=blue]Time: %s[/color]" % Manager.utility.format_time(World.main.time_elapsed)
	var current_record: float = Manager.utility.get_personal_record()
	if World.main.time_elapsed < current_record:
		Manager.utility.set_personal_record(World.main.time_elapsed)
		time_label.text += " [color=deep_pink][wave](New Record!)[/wave][/color]"
	else:
		time_label.text += " (PR: %s)" % Manager.utility.format_time(current_record)
	await Manager.audio.play_credit_music()
	Manager.audio.play_main_music()
