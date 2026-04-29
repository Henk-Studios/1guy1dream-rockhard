## Main menu UI with play, settings, and quit options
extends Control
class_name Menu

@export var play_button: Button
@export var settings_button: Button
@export var quit_button: Button

@export var settings_menu: SettingsMenu

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
			
func _on_play_button_pressed() -> void:
	Manager.scene.change_scene("res://scenes/world.tscn", {
		"you can add": "parameters here if needed"
	})

func _on_settings_button_pressed() -> void:
	settings_menu.show_settings()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
