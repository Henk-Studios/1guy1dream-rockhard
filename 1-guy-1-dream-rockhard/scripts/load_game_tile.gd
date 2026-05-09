extends MarginContainer
class_name LoadGameTile
@onready var name_field: LineEdit = $VBoxContainer/HBoxContainer/NameField
@onready var load_button: Button = $VBoxContainer/HBoxContainer/PlayButton
@onready var delete_button: Button = $VBoxContainer/HBoxContainer/DeleteButton
@onready var playtime_label: Label = $VBoxContainer/HBoxContainer2/TimeLabel
@onready var last_played_label: Label = $VBoxContainer/HBoxContainer2/DateLabel

var save_path: String = ""

func set_save_path(path: String) -> void:
	save_path = path

func _on_name_field_text_changed(new_text: String) -> void:
	if save_path.is_empty():
		return

	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return

	var world_data: Dictionary = {}
	var existing_data = config.get_value("world", "data", {})
	if typeof(existing_data) == TYPE_DICTIONARY:
		world_data = existing_data

	var world_name := new_text.strip_edges()
	if world_name.is_empty():
		world_name = "Unnamed World"

	world_data["name"] = world_name
	config.set_value("world", "data", world_data)
	if config.save(save_path) != OK:
		push_error("Failed to save world name: %s" % save_path)