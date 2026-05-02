class_name PauseMenu
extends Control

@export var back_button: Button
@export var quit_button: Button
@export var click_blocker: ColorRect


func _ready():
	hide()
	back_button.pressed.connect(_on_back_button_pressed)
	back_button.mouse_entered.connect(_on_button_mouse_entered)
	click_blocker.gui_input.connect(_on_click_blocker_input)
	quit_button.pressed.connect(_on_quit_button_pressed)
	quit_button.mouse_entered.connect(_on_button_mouse_entered)

# input
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and not visible:
			show_pause_menu()
		elif event.keycode == KEY_ESCAPE and visible:
			hide_pause_menu()

func show_pause_menu():
	visible = true
	get_tree().paused = true
	
func hide_pause_menu():
	visible = false
	get_tree().paused = false

func _on_button_mouse_entered():
	Manager.audio.play_hover_sfx()

func _on_back_button_pressed():
	Manager.audio.play_click_sfx()
	hide_pause_menu()

func _on_quit_button_pressed():
	Manager.audio.play_click_sfx()
	get_tree().paused = false
	Manager.message.clear()
	Manager.scene.change_scene("res://scenes/main_menu.tscn")

func _on_click_blocker_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Manager.audio.play_click_sfx()
			hide_pause_menu()
