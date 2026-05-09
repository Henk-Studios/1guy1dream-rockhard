## Handles scene transitions with loading screens and fade effects
## Use change_scene(scene_path, params) to switch scenes with a loading screen.
## Use setup(params) in your scenes to receive parameters when loaded.
extends Node
class_name SceneManager

# Scene Manager - handles scene switching and management

var previous_scene: String = ""
var current_scene: Node = null
@export var main_scene_path := "res://scenes/UI/menus/menu.tscn"
# Loading screen components
@onready var loading_mouse_blocker: ColorRect = $CanvasLayer/SplashScreen/ColorRect
@onready var loading_screen: CanvasLayer = $CanvasLayer
@onready var loading_screen_control: Control = $CanvasLayer/SplashScreen
var tween: Tween = null

# Loading screen settings
var fade_duration: float = 0.5

func change_scene(scene_path: String, params: Dictionary = {}) -> void:
	print("Changing scene to: " + scene_path)
	await _show_loading_screen(true)
	# Wait one frame to ensure loading screen is visible
	await get_tree().process_frame
	await _remove_current_scene()
	_load_new_scene(scene_path, params)

func _remove_current_scene() -> void:
	if not current_scene:
		return
	previous_scene = current_scene.scene_file_path
	current_scene.queue_free()
	current_scene = null
	# Wait one frame to ensure the node is freed
	await get_tree().process_frame

func _load_new_scene(scene_path: String, params: Dictionary) -> void:
	var packed_scene = load(scene_path)
	if not packed_scene:
		Manager.message.error("Failed to load scene: " + scene_path)
		await Manager.time.wait_frames(1).timeout
		push_error("Failed to load scene: " + scene_path)
		return
	current_scene = packed_scene.instantiate()
	add_child(current_scene)
	if current_scene.has_method("setup"):
		current_scene.setup(params)
	else:
		await _hide_loading_screen(true)
		
func get_current_scene() -> Node:
	return current_scene

func get_previous_scene_path() -> String:
	return previous_scene

func reload_scene(params: Dictionary = {}) -> void:
	var scene_path = current_scene.scene_file_path
	await _show_loading_screen()
	# Wait one frame to ensure loading screen is visible
	await get_tree().process_frame
	await _remove_current_scene()
	_load_new_scene(scene_path, params)

func load_initial_scene() -> void:
	await _show_loading_screen()
	# Wait one frame to ensure loading screen is visible
	await get_tree().process_frame
	_load_new_scene(main_scene_path, {})

func _show_loading_screen(fade_in: bool = false) -> void:
	loading_screen.visible = true
	if fade_in:
		loading_screen_control.modulate.a = 0.0
		tween = create_tween()
		tween.tween_property(loading_screen_control, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE)
		await tween.finished
	loading_screen_control.modulate.a = 1.0
	# Block input during loading
	loading_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_STOP

func _hide_loading_screen(fade_out: bool = false) -> void:
	if fade_out:
		tween = create_tween()
		tween.tween_property(loading_screen_control, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE)
		await tween.finished
	loading_screen.visible = false
	# Don't block input when invisible
	loading_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_go_back_button_pressed() -> void:
	change_scene(main_scene_path)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Ctrl+Shift+R: Reload current scene
		if event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_R:
			Manager.message.info("Reloading current scene...")
			reload_scene()
			get_viewport().set_input_as_handled()
		
		# Ctrl+Shift+M: Go to main menu scene
		elif event.ctrl_pressed and event.shift_pressed and event.keycode == KEY_M:
			Manager.message.info("Going to main menu scene...")
			change_scene(main_scene_path)
			get_viewport().set_input_as_handled()

# Other scripts that use setup() can call this when they finish loading
func finish_loading() -> void:
	await _hide_loading_screen(true)
