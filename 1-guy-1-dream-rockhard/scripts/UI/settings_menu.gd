## Settings menu UI for volume, display, and gameplay options
class_name SettingsMenu
extends Control

# Node references
@export var master_volume_slider: HSlider
@export var music_volume_slider: HSlider
@export var sfx_volume_slider: HSlider
@export var ui_scale_slider: HSlider
@export var fullscreen_toggle: CheckButton
@export var fps_toggle: CheckButton
@export var follow_mouse_toggle: CheckButton
@export var auto_shoot_toggle: CheckButton
@export var clear_player_data_button: Button
@export var back_button: Button
@export var click_blocker: ColorRect
@export var is_main_settings: bool = true
@export var player_section: Control
signal player_data_cleared

# UI Scale constants
const MIN_UI_SCALE := 0.6
const MAX_UI_SCALE := 1.3
const DEFAULT_UI_SCALE := 1.0
const FULLSCREEN_SECTION := "display"
const FULLSCREEN_KEY := "fullscreen"
const FULLSCREEN_DEFAULT := true

# Gameplay constants
const GAMEPLAY_SECTION := "gameplay"
const FOLLOW_MOUSE_KEY := "follow_mouse"
const AUTO_SHOOT_KEY := "auto_shoot"
const FOLLOW_MOUSE_DEFAULT := false
const AUTO_SHOOT_DEFAULT := false

func _ready():
	# Load UI scale setting on startup
	_load_and_apply_ui_scale()
	_load_and_apply_fullscreen()
	
	# Load and apply volume settings
	_load_and_apply_volumes()
	
	# Connect button signals
	clear_player_data_button.pressed.connect(_on_clear_player_data_pressed)
	clear_player_data_button.mouse_entered.connect(_on_button_mouse_entered)
	back_button.pressed.connect(_on_back_button_pressed)
	back_button.mouse_entered.connect(_on_button_mouse_entered)
	click_blocker.gui_input.connect(_on_click_blocker_input)
	
	# Connect slider signals
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_scale_slider.drag_ended.connect(_on_ui_scale_drag_ended)

	# connect Checkbuttons
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggle_toggled)
	if fps_toggle:
		fps_toggle.toggled.connect(_on_fps_toggle_toggled)
	if follow_mouse_toggle:
		follow_mouse_toggle.toggled.connect(_on_follow_mouse_toggle_toggled)
	if auto_shoot_toggle:
		auto_shoot_toggle.toggled.connect(_on_auto_shoot_toggle_toggled)

	if not is_main_settings:
		player_section.hide()
	
	
	# Initialize sliders with current values
	_initialize_sliders()
	_sync_fullscreen_toggle()
	_sync_gameplay_toggles()

func _initialize_sliders():
	master_volume_slider.value = Manager.audio.get_master_volume()
	music_volume_slider.value = Manager.audio.get_music_volume()
	sfx_volume_slider.value = Manager.audio.get_sfx_volume()
	# UI scale slider value is from 0 to 1, map current scale to that range
	ui_scale_slider.value = (_get_current_ui_scale() - MIN_UI_SCALE) / (MAX_UI_SCALE - MIN_UI_SCALE)

func show_settings():
	visible = true
	_initialize_sliders()
	_sync_fullscreen_toggle()
	_sync_gameplay_toggles()

func hide_settings():
	visible = false

func _on_button_mouse_entered():
	Manager.audio.play_hover_sfx()

func _on_back_button_pressed():
	Manager.audio.play_click_sfx()
	hide_settings()

func _on_click_blocker_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Manager.audio.play_click_sfx()
			hide_settings()

func _input(event: InputEvent):
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			hide_settings()

# Volume change handlers
func _on_master_volume_changed(value: float):
	Manager.audio.set_master_volume(value)
	Manager.utility.save_setting("audio", "master_volume", value)

func _on_music_volume_changed(value: float):
	Manager.audio.set_music_volume(value)
	Manager.utility.save_setting("audio", "music_volume", value)

func _on_sfx_volume_changed(value: float):
	Manager.audio.set_sfx_volume(value)
	Manager.utility.save_setting("audio", "sfx_volume", value)

# UI Scale handlers
func _on_ui_scale_drag_ended(value_changed: bool):
	if value_changed:
		# Get current slider value (0 to 1) and map it to MIN_UI_SCALE to MAX_UI_SCALE
		var value = ui_scale_slider.value
		var lscale = lerp(MIN_UI_SCALE, MAX_UI_SCALE, value)
		_set_ui_scale(lscale)

func _set_ui_scale(lscale: float):
	"""Set and save the UI scale"""
	var ui_scale = clamp(lscale, MIN_UI_SCALE, MAX_UI_SCALE)
	get_tree().root.content_scale_factor = ui_scale
	Manager.utility.save_setting("ui", "scale", ui_scale)

func _get_current_ui_scale() -> float:
	"""Get the current UI scale from the window"""
	return get_tree().root.content_scale_factor

func _load_and_apply_ui_scale():
	"""Load UI scale from settings and apply it"""
	var ui_scale: float = Manager.utility.load_setting("ui", "scale", DEFAULT_UI_SCALE)
	ui_scale = clamp(ui_scale, MIN_UI_SCALE, MAX_UI_SCALE)
	get_tree().root.content_scale_factor = ui_scale

func _load_and_apply_fullscreen() -> void:
	var is_fullscreen: bool = Manager.utility.load_setting(FULLSCREEN_SECTION, FULLSCREEN_KEY, FULLSCREEN_DEFAULT)
	_apply_fullscreen(is_fullscreen)
	_sync_fullscreen_toggle()

func _sync_fullscreen_toggle() -> void:
	if fullscreen_toggle:
		fullscreen_toggle.set_pressed_no_signal(Manager.utility.load_setting(FULLSCREEN_SECTION, FULLSCREEN_KEY, FULLSCREEN_DEFAULT))
	if fps_toggle:
		fps_toggle.set_pressed_no_signal(Manager.utility.fps_visible)

func _load_and_apply_volumes():
	"""Load volume settings and apply them to the audio manager"""
	var master_volume: float = Manager.utility.load_setting("audio", "master_volume", 0.5)
	var music_volume: float = Manager.utility.load_setting("audio", "music_volume", 1.0)
	var sfx_volume: float = Manager.utility.load_setting("audio", "sfx_volume", 1.0)
	
	Manager.audio.set_master_volume(master_volume)
	Manager.audio.set_music_volume(music_volume)
	Manager.audio.set_sfx_volume(sfx_volume)

func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	_apply_fullscreen(toggled_on)
	Manager.utility.save_setting(FULLSCREEN_SECTION, FULLSCREEN_KEY, toggled_on)

func _on_fps_toggle_toggled(toggled_on: bool) -> void:
	Manager.utility.set_fps_visible(toggled_on)

func _apply_fullscreen(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Gameplay toggle handlers
func _on_follow_mouse_toggle_toggled(toggled_on: bool) -> void:
	Manager.follow_mouse = toggled_on
	Manager.utility.save_setting(GAMEPLAY_SECTION, FOLLOW_MOUSE_KEY, toggled_on)

func _on_auto_shoot_toggle_toggled(toggled_on: bool) -> void:
	Manager.auto_shoot = toggled_on
	Manager.utility.save_setting(GAMEPLAY_SECTION, AUTO_SHOOT_KEY, toggled_on)

func _sync_gameplay_toggles() -> void:
	if follow_mouse_toggle:
		var follow_mouse_value: bool = Manager.utility.load_setting(GAMEPLAY_SECTION, FOLLOW_MOUSE_KEY, FOLLOW_MOUSE_DEFAULT)
		follow_mouse_toggle.set_pressed_no_signal(follow_mouse_value)
		Manager.follow_mouse = follow_mouse_value
	if auto_shoot_toggle:
		var auto_shoot_value: bool = Manager.utility.load_setting(GAMEPLAY_SECTION, AUTO_SHOOT_KEY, AUTO_SHOOT_DEFAULT)
		auto_shoot_toggle.set_pressed_no_signal(auto_shoot_value)
		Manager.auto_shoot = auto_shoot_value

func _on_clear_player_data_pressed() -> void:
	Manager.audio.play_click_sfx()
	Manager.utility.clear_player_data()
	await Manager.utility.clear_player_data_from_firebase()
	player_data_cleared.emit()
