extends Control
class_name LoadMenu
@export var load_game_tile_scene: PackedScene
@onready var load_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var click_blocker: ColorRect = $ClickBlocker

func _ready() -> void:
	hide()
	back_button.pressed.connect(_on_back_button_pressed)
	back_button.mouse_entered.connect(_on_button_mouse_entered)
	click_blocker.gui_input.connect(_on_click_blocker_input)

func show_menu() -> void:
	# Populate save list and show UI
	_populate()
	visible = true
	grab_focus()

func hide_menu() -> void:
	visible = false

func _populate() -> void:
	# Clear existing children
	for child in load_container.get_children():
		child.queue_free()

	var entries = Manager.utility.get_save_entries()
	if entries.is_empty():
		return
	for entry in entries:
		var path: String = entry["path"]
		var data: Dictionary = entry["data"]

		var tile := load_game_tile_scene.instantiate() as LoadGameTile
		# Fill in UI fields if present on the tile
		if tile.has_node("VBoxContainer/HBoxContainer/NameField"):
			var name_field = tile.get_node("VBoxContainer/HBoxContainer/NameField") as LineEdit
			name_field.text = str(data.get("name", "Unnamed World"))
		if tile.has_node("VBoxContainer/HBoxContainer2/WorldIdLabel"):
			var world_id_label = tile.get_node("VBoxContainer/HBoxContainer2/WorldIdLabel") as Label
			world_id_label.text = "ID: %s" % str(entry["world_id"])
		if tile.has_node("VBoxContainer/HBoxContainer2/TimeLabel"):
			var time_label = tile.get_node("VBoxContainer/HBoxContainer2/TimeLabel") as Label
			var t = float(data["time_elapsed"]) if data.has("time_elapsed") and data["time_elapsed"] != null else 0.0
			time_label.text = "%02d:%02d" % [int(t) / 60, int(t) % 60]
		if tile.has_node("VBoxContainer/HBoxContainer2/DateLabel"):
			var date_label = tile.get_node("VBoxContainer/HBoxContainer2/DateLabel") as Label
			date_label.text = str(data["last_played"]) if data.has("last_played") and data["last_played"] != null else "Unknown"
		if tile.has_node("VBoxContainer/HBoxContainer2/TypeLabel"):
			var type_label = tile.get_node("VBoxContainer/HBoxContainer2/TypeLabel") as Label
			var world_type: String = "Classic"
			var rising_lava: bool = data.get("rising_lava_enabled", false) if data.has("rising_lava_enabled") else false
			var gamemode: String = data.get("gamemode", "") if data.has("gamemode") else ""
			if rising_lava:
				world_type = "Rising Lava"
			elif gamemode == "infinite":
				world_type = "Infinite"
			type_label.text = "%s" % world_type

		tile.set_save_path(path)
		load_container.add_child(tile)

		# Connect buttons
		if tile.has_node("VBoxContainer/HBoxContainer/PlayButton"):
			var pb = tile.get_node("VBoxContainer/HBoxContainer/PlayButton") as Button
			pb.pressed.connect(Callable(self , "_on_tile_load_pressed").bind(path))
		if tile.has_node("VBoxContainer/HBoxContainer/DeleteButton"):
			var db = tile.get_node("VBoxContainer/HBoxContainer/DeleteButton") as Button
			db.pressed.connect(Callable(self , "_on_tile_delete_pressed").bind(path, tile))
		if tile.has_node("VBoxContainer/HBoxContainer/NameField"):
			var name_field = tile.get_node("VBoxContainer/HBoxContainer/NameField") as LineEdit
			name_field.text_changed.connect(Callable(tile, "_on_name_field_text_changed"))

func _on_tile_load_pressed(save_path: String) -> void:
	var config := ConfigFile.new()
	var err := config.load(save_path)
	if err != OK:
		Manager.message.info("Failed to load save")
		return
	var data = config.get_value("world", "data", null)
	if data == null:
		Manager.message.info("Invalid save")
		return
	var params := {}
	if data.has("seed") and data["seed"] != null:
		params["seed"] = data["seed"]
	params["save_path"] = save_path
	params["load_data"] = data
	Manager.scene.change_scene("res://scenes/world.tscn", params)

func _on_tile_delete_pressed(save_path: String, tile: Node) -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		if tile:
			tile.queue_free()
		Manager.message.info("Save deleted")


func _on_button_mouse_entered():
	Manager.audio.play_hover_sfx()

func _on_back_button_pressed():
	Manager.audio.play_click_sfx()
	hide_menu()

func _on_click_blocker_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Manager.audio.play_click_sfx()
			hide_menu()
