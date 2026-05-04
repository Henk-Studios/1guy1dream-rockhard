extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(__) -> void:
	if Manager.scene.current_scene:
		text = Manager.utility.format_time(World.main.time_elapsed)
