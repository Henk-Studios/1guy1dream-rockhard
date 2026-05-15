extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(__) -> void:
	if Manager.scene.current_scene:
		if World.main.gamemode == Manager.utility.GameType.RACE_TO_SPACE:
			text = Manager.utility.format_time(max(0, 300.0 - World.main.time_elapsed))
		elif World.main.gamemode == Manager.utility.GameType.RACE_TO_RICHES:
			text = Manager.utility.format_time(max(0, 600.0 - World.main.time_elapsed))
		else:
			text = Manager.utility.format_time(World.main.time_elapsed)
