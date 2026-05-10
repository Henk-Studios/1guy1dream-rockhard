## Manages utility functions including game settings, FPS counter, and player data
extends Node
class_name UtilityManager

signal personal_record_updated(time_seconds: float, game_type: String)

# Settings file path
const SETTINGS_PATH := "user://game_settings.cfg"
const PLAYER_DATA_PATH := "user://player_data.cfg"

const UI_SECTION := "ui"
const FPS_COUNTER_KEY := "fps_visible"

const PLAYER_SECTION := "player"
const PERSONAL_RECORD_KEY := "personal_records"

# Game type constants
const GAME_TYPE_NORMAL := "normal"
const GAME_TYPE_INFINITE := "infinite"
const GAME_TYPE_INFINITE_RISING_LAVA := "infinite_rising_lava"

# Seed type constants
const SEED_TYPE_SET := "set"
const SEED_TYPE_RANDOM := "random"

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

func format_time(seconds: float) -> String:
	if seconds == INF:
		return "N/A"
	var total: int = int(seconds)
	var minutes: int = total / 60
	var secs: int = total % 60
	var cs: int = int((seconds - float(total)) * 100.0)
	return "%02d:%02d.%02d" % [minutes, secs, cs]

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


func intify(text) -> int:
	if typeof(text) == TYPE_INT:
		return text
	var result: int = 0
	for charr in text:
		result += ord(charr)
	return result

# Player Data Management

func _get_all_personal_records() -> Dictionary:
	"""Get all personal records as a dictionary: {game_type:seed_type: time}"""
	var records = load_player_data(PLAYER_SECTION, PERSONAL_RECORD_KEY, {})
	if not records is Dictionary:
		records = {}
	# Ensure all game type + seed type combinations exist
	for game_type in [GAME_TYPE_NORMAL, GAME_TYPE_INFINITE, GAME_TYPE_INFINITE_RISING_LAVA]:
		for seed_type in [SEED_TYPE_SET, SEED_TYPE_RANDOM]:
			var key = "%s:%s" % [game_type, seed_type]
			if not records.has(key):
				records[key] = INF if game_type != GAME_TYPE_INFINITE_RISING_LAVA else 0.0
	return records

func _save_all_personal_records(records: Dictionary) -> void:
	"""Save all personal records"""
	save_player_data(PLAYER_SECTION, PERSONAL_RECORD_KEY, records)

func get_current_game_type() -> String:
	"""Determine the current game type based on world state.
	Rising lava is a modifier on the gamemode, so we check that first."""
	if not is_instance_valid(World.lava):
		return GAME_TYPE_NORMAL
	
	if World.lava.rising_lava:
		return GAME_TYPE_INFINITE_RISING_LAVA
	
	# Check if infinite mode was enabled by looking at terrain layers count
	# In infinite mode, many layers are generated. Normal mode has a fixed set.
	if is_instance_valid(World.terrain) and World.terrain.terrain_config.has("layers"):
		var layer_count = World.terrain.terrain_config.layers.size()
		# Normal mode typically has 6 layers (dirt + 5 stone layers)
		# Infinite mode generates many more layers (up to 34)
		if layer_count > 10:
			return GAME_TYPE_INFINITE
	
	return GAME_TYPE_NORMAL

func get_current_seed_type() -> String:
	"""Determine the current seed type based on world state.
	Returns SEED_TYPE_SET if a seed was explicitly provided, SEED_TYPE_RANDOM otherwise."""
	if not is_instance_valid(World.main):
		return SEED_TYPE_RANDOM
	return World.main.seed_type_used

func get_personal_record(game_type: String = "", seed_type: String = "") -> float:
	"""Get the player's personal best time for a specific game type and seed type.
	If game_type is empty, uses current game type.
	If seed_type is empty, uses current seed type.
	Returns INF for normal/infinite (lower is better), 0.0 for infinite_rising_lava (higher is better)."""
	if game_type == "":
		game_type = get_current_game_type()
	if seed_type == "":
		seed_type = get_current_seed_type()
	
	var key = "%s:%s" % [game_type, seed_type]
	var records = _get_all_personal_records()
	if not records.has(key):
		return INF if game_type != GAME_TYPE_INFINITE_RISING_LAVA else 0.0
	return records[key]

func set_personal_record(time_seconds: float, game_type: String = "", seed_type: String = "") -> void:
	"""Update the personal record for a specific game type and seed type if the new time is better.
	If game_type is empty, uses current game type.
	If seed_type is empty, uses current seed type.
	For normal/infinite: lower time is better. For infinite_rising_lava: higher time is better."""
	if game_type == "":
		game_type = get_current_game_type()
	if seed_type == "":
		seed_type = get_current_seed_type()
	
	var key = "%s:%s" % [game_type, seed_type]
	var records = _get_all_personal_records()
	var current_record = records.get(key, INF if game_type != GAME_TYPE_INFINITE_RISING_LAVA else 0.0)
	
	# Determine if this is a new record
	var is_new_record = false
	if game_type == GAME_TYPE_INFINITE_RISING_LAVA:
		# For rising lava: higher time is better
		is_new_record = time_seconds > current_record
	else:
		# For normal/infinite: lower time is better
		is_new_record = time_seconds < current_record
	
	if is_new_record:
		records[key] = time_seconds
		_save_all_personal_records(records)
		personal_record_updated.emit(time_seconds, game_type)

func get_all_personal_records() -> Dictionary:
	"""Get all personal records for all game types"""
	return _get_all_personal_records()

func save_player_data(section: String, key: String, value: Variant) -> void:
	"""Save player data to the player data file"""
	var config := ConfigFile.new()
	config.load(PLAYER_DATA_PATH) # Load existing data
	config.set_value(section, key, value)
	
	var err := config.save(PLAYER_DATA_PATH)
	if err != OK:
		push_error("Failed to save player data: %s/%s" % [section, key])

func load_player_data(section: String, key: String, default_value: Variant) -> Variant:
	"""Load player data from the player data file"""
	var config := ConfigFile.new()
	var err := config.load(PLAYER_DATA_PATH)
	
	if err == OK:
		return config.get_value(section, key, default_value)
	else:
		return default_value

func has_player_data(section: String, key: String) -> bool:
	"""Check if player data exists"""
	var config := ConfigFile.new()
	var err := config.load(PLAYER_DATA_PATH)
	
	if err == OK:
		return config.has_section_key(section, key)
	return false

func clear_player_data() -> void:
	"""Clear all player data"""
	var config := ConfigFile.new()
	config.load(PLAYER_DATA_PATH)
	config.clear()
	config.save(PLAYER_DATA_PATH)
	Manager.message.info(" All player data cleared")


const SAVE_DIR := "user://worlds"
const LEGACY_SAVE_PATH := "user://world_save.cfg"

func ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func generate_world_id() -> String:
	return "%d_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi()]

func world_id_to_save_path(world_id: String) -> String:
	return "%s/%s.cfg" % [SAVE_DIR, world_id]

func resolve_world_id(save_path: String, data: Dictionary = {}) -> String:
	if data.has("world_id") and data["world_id"] != null and str(data["world_id"]) != "":
		return str(data["world_id"])
	if save_path != "":
		return save_path.get_file().get_basename()
	return ""

func get_save_paths() -> Array:
	ensure_save_dir()
	var paths: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		while true:
			var file_name := dir.get_next()
			if file_name == "":
				break
			if dir.current_is_dir():
				continue
			if not file_name.ends_with(".cfg"):
				continue
			paths.append("%s/%s" % [SAVE_DIR, file_name])
		dir.list_dir_end()

	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		paths.append(LEGACY_SAVE_PATH)

	return paths

func get_save_entries() -> Array:
	var entries: Array = []
	for path in get_save_paths():
		var config := ConfigFile.new()
		if config.load(path) != OK:
			continue
		var data = config.get_value("world", "data", null)
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var world_data: Dictionary = data
		entries.append({
			"path": path,
			"data": world_data,
			"world_id": resolve_world_id(path, world_data),
			"world_name": str(world_data.get("name", "Unnamed World")),
			"time_elapsed": float(world_data.get("time_elapsed", 0.0)),
			"last_played": str(world_data.get("last_played", "Unknown")),
			"save_timestamp": int(world_data.get("save_timestamp", 0))
		})

	entries.sort_custom(_sort_entries_desc)
	return entries

func get_latest_save_entry() -> Dictionary:
	var entries := get_save_entries()
	if entries.is_empty():
		return {}
	return entries[0]

func _sort_entries_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("save_timestamp", 0)) > int(b.get("save_timestamp", 0))