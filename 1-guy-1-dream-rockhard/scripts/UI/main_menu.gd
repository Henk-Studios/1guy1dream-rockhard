## Main menu UI with play, settings, and quit options
extends Control
class_name Menu

@export var play_classic_button: Button
@export var play_infinite_button: Button
@export var play_infinite_rising_lava_button: Button
@export var continue_button: Button
@export var load_game_save_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var seed_input: LineEdit
@export var name_input: LineEdit
@export var dev_button: Button
@export var pr_label: RichTextLabel

@export var settings_menu: SettingsMenu
@export var load_menu: LoadMenu

func _ready() -> void:
	play_classic_button.pressed.connect(_on_play_button_pressed.bind("classic"))
	play_infinite_button.pressed.connect(_on_play_button_pressed.bind("infinite"))
	play_infinite_rising_lava_button.pressed.connect(_on_play_button_pressed.bind("infinite_rising_lava"))
	continue_button.pressed.connect(_on_continue_button_pressed)
	load_game_save_button.pressed.connect(_on_load_game_save_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	play_classic_button.mouse_entered.connect(_on_button_mouse_entered)
	continue_button.mouse_entered.connect(_on_button_mouse_entered)
	load_game_save_button.mouse_entered.connect(_on_button_mouse_entered)
	settings_button.mouse_entered.connect(_on_button_mouse_entered)
	quit_button.mouse_entered.connect(_on_button_mouse_entered)
	dev_button.pressed.connect(_on_dev_button_pressed)
	set_pr_label()
	settings_menu.player_data_cleared.connect(set_pr_label)
	play_classic_button.grab_focus()

func set_pr_label() -> void:
	var classic_pr_set = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GAME_TYPE_NORMAL, Manager.utility.SEED_TYPE_SET))
	var classic_pr_random = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GAME_TYPE_NORMAL, Manager.utility.SEED_TYPE_RANDOM))
	var infinite_pr_set = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GAME_TYPE_INFINITE, Manager.utility.SEED_TYPE_SET))
	var infinite_pr_random = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GAME_TYPE_INFINITE, Manager.utility.SEED_TYPE_RANDOM))
	var lava_pr_set = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GAME_TYPE_INFINITE_RISING_LAVA, Manager.utility.SEED_TYPE_SET))
	var lava_pr_random = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GAME_TYPE_INFINITE_RISING_LAVA, Manager.utility.SEED_TYPE_RANDOM))
	pr_label.text = "\n\nPersonal Records:\nClassic Set Seed: %s\nClassic Random Seed: %s\nInfinite Set Seed: %s\nInfinite Random Seed: %s\nRising Lava Set Seed: %s\nRising Lava Random Seed: %s" % [classic_pr_set, classic_pr_random, infinite_pr_set, infinite_pr_random, lava_pr_set, lava_pr_random]
			
func _on_play_button_pressed(game_mode: String) -> void:
	Manager.audio.play_click_sfx()
	var params := {}
	if seed_input.text != "":
		params["seed"] = seed_input.text
	if name_input.text != "":
		params["name"] = name_input.text
	if game_mode == "infinite_rising_lava":
		params["rising_lava"] = true
	if game_mode == "infinite" or game_mode == "infinite_rising_lava":
		params["gamemode"] = Manager.utility.GAME_TYPE_INFINITE
	else:
		params["gamemode"] = Manager.utility.GAME_TYPE_NORMAL
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
		Manager.dev_mode = not Manager.dev_mode
