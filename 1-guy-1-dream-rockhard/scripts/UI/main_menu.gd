## Main menu UI with play, settings, and quit options
extends Control
class_name Menu

@export var play_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var seed_input: LineEdit
@export var dev_button: Button

@export var settings_menu: SettingsMenu

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	play_button.mouse_entered.connect(_on_button_mouse_entered)
	settings_button.mouse_entered.connect(_on_button_mouse_entered)
	quit_button.mouse_entered.connect(_on_button_mouse_entered)
	dev_button.pressed.connect(_on_dev_button_pressed)

	play_button.grab_focus()
			
func _on_play_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	if seed_input.text != "":
		# convert any input to integer
		var seed_value: int = intify(seed_input.text)
		Manager.scene.change_scene("res://scenes/world.tscn", {
			"seed": seed_value
		})
	else:
		Manager.scene.change_scene("res://scenes/world.tscn")

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
