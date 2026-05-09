## Main menu UI with play, settings, and quit options
extends Control
class_name Menu

@export var play_new_button: Button
@export var continue_button: Button
@export var load_game_save_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var seed_input: LineEdit
@export var name_input: LineEdit
@export var dev_button: Button

@export var settings_menu: SettingsMenu
@export var load_menu: LoadMenu

func _ready() -> void:
	play_new_button.pressed.connect(_on_play_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	load_game_save_button.pressed.connect(_on_load_game_save_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	play_new_button.mouse_entered.connect(_on_button_mouse_entered)
	continue_button.mouse_entered.connect(_on_button_mouse_entered)
	load_game_save_button.mouse_entered.connect(_on_button_mouse_entered)
	settings_button.mouse_entered.connect(_on_button_mouse_entered)
	quit_button.mouse_entered.connect(_on_button_mouse_entered)
	dev_button.pressed.connect(_on_dev_button_pressed)

	play_new_button.grab_focus()
			
func _on_play_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	var params := {}
	if seed_input.text != "":
		# convert any input to integer
		var seed_value: int = intify(seed_input.text)
		params["seed"] = seed_value
	if name_input.text != "":
		params["name"] = name_input.text
	Manager.scene.change_scene("res://scenes/world.tscn", params)

func _on_continue_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	# Try to load the most recent saved world and pass it to the world scene as params
	var entry = Manager.utility.get_latest_save_entry()
	if entry.is_empty():
		Manager.message.info("No saved game found")
		return
	var data: Dictionary = entry["data"]
	var params := {}
	if data.has("seed") and data["seed"] != null:
		params["seed"] = data["seed"]
	params["save_path"] = entry["path"]
	params["load_data"] = data
	Manager.scene.change_scene("res://scenes/world.tscn", params)

func _on_load_game_save_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	load_menu.show_menu()

func _on_settings_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	settings_menu.show_settings()

func _on_quit_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	get_tree().quit()

func _on_button_mouse_entered() -> void:
	Manager.audio.play_hover_sfx()

var dev_click_count: int = 0

func _on_dev_button_pressed() -> void:
	dev_click_count += 1
	if dev_click_count >= 3:
		Manager.message.info("???")
		World.dev_mode = not World.dev_mode

func intify(text: String) -> int:
	var result: int = 0
	for charr in text:
		result += ord(charr)
	return result
