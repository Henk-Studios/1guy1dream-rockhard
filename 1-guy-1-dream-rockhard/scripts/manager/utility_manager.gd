## Manages utility functions including game settings, FPS counter, and player data
extends Node
class_name UtilityManager

signal player_name_changed(new_name: String)
signal tutorial_completed_changed(completed: bool)

# Settings file path
const SETTINGS_PATH := "user://game_settings.cfg"

const UI_SECTION := "ui"
const FPS_COUNTER_KEY := "fps_visible"

var fps_visible: bool = false
var fps_message_timer: Timer

var tutorial_session_active: bool = false

func _ready() -> void:
	_setup_fps_timer()
	
	fps_visible = load_setting(UI_SECTION, FPS_COUNTER_KEY, false)
	if fps_visible:
		fps_message_timer.start(0.1)

func _setup_fps_timer() -> void:
	self.fps_message_timer = Timer.new()
	self.fps_message_timer.one_shot = false
	self.fps_message_timer.timeout.connect(_on_fps_timer_timeout)
	add_child(self.fps_message_timer)

func _on_fps_timer_timeout() -> void:
		var fps = Engine.get_frames_per_second()
		Manager.message.info("FPS: %d" % fps, 0.5)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F and event.ctrl_pressed and event.shift_pressed:
			toggle_fps_counter()

func toggle_fps_counter() -> void:
	set_fps_visible(! self.fps_visible)

func set_fps_visible(visible: bool) -> void:
	self.fps_visible = visible
	save_setting(UI_SECTION, FPS_COUNTER_KEY, self.fps_visible)
	
	if self.fps_visible:
		self.fps_message_timer.start(0.1)
		Manager.message.info("FPS counter enabled")
	else:
		self.fps_message_timer.stop()
		Manager.message.info("FPS counter disabled")

func is_mouse_over_ui(ui_nodes: Array) -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	for ui_node in ui_nodes:
		if ui_node is Control:
			var rect: Rect2 = ui_node.get_global_rect()
			if rect.has_point(mouse_pos) and ui_node.is_visible_in_tree():
				# print("Mouse is over UI node: ", ui_node.name)	
				return true
	return false

# Settings Management

func save_setting(section: String, key: String, value: Variant) -> void:
	"""Save a setting to the game settings file"""
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH) # Load existing settings
	config.set_value(section, key, value)
	
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save setting: %s/%s" % [section, key])

func load_setting(section: String, key: String, default_value: Variant) -> Variant:
	"""Load a setting from the game settings file"""
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	
	if err == OK:
		return config.get_value(section, key, default_value)
	else:
		return default_value

func has_setting(section: String, key: String) -> bool:
	"""Check if a setting exists"""
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	
	if err == OK:
		return config.has_section_key(section, key)
	return false