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

# The version of the game data format. Increment this when making changes that invalidate old save data.
const DATA_VERSION := 2

# The public game version, shown to players. Increment this for any player-facing changes or updates.
# You can add game-version-specific messages to firebase, for example to notify players of updates or changes that may affect them.
const GAME_VERSION := "1.0.1"

# Seed type constants
const SEED_TYPE_SET := "set"
const SEED_TYPE_RANDOM := "random"

enum GameType {
	CLASSIC,
	INFINITE,
	INFINITE_RISING_LAVA,
	RACE_TO_SPACE,
	RACE_TO_RICHES,
}

enum SeedType {
	SET,
	RANDOM
}

enum ScoreFormats {
	TIME,
	MONEY,
	HEIGHT
}

# Centralized game-type definitions.
# Each entry contains display name, score key names for set/random seeds,
# and whether a higher score is considered better for that gamemode.
const GAME_TYPE_DEFINITIONS: Dictionary[GameType, Dictionary] = {
	GameType.CLASSIC: {
		"display_name": "Classic",
		"score_key_set": "ss_classic",
		"score_key_random": "rs_classic",
		"higher_is_better": false,
		"min_reasonable": 20.0,
		"max_reasonable": 3600.0 * 48,
		"format": ScoreFormats.TIME,
		"infinite_layers": false,
		"show_credits": true
	},
	GameType.INFINITE: {
		"display_name": "Infinite",
		"score_key_set": "ss_infinite",
		"score_key_random": "rs_infinite",
		"higher_is_better": false,
		"min_reasonable": 20.0,
		"max_reasonable": 3600.0 * 48,
		"format": ScoreFormats.TIME,
		"infinite_layers": true,
		"show_credits": true
	},
	GameType.INFINITE_RISING_LAVA: {
		"display_name": "Rising Lava",
		"score_key_set": "ss_lava",
		"score_key_random": "rs_lava",
		"higher_is_better": true,
		"min_reasonable": 0.0,
		"max_reasonable": 9999999999.0,
		"format": ScoreFormats.TIME,
		"infinite_layers": true,
		"rising_lava": true
	},
	GameType.RACE_TO_SPACE: {
		"display_name": "Race to Space",
		"score_key_set": "ss_race_to_space",
		"score_key_random": "rs_race_to_space",
		"higher_is_better": true,
		"min_reasonable": 0.0,
		"max_reasonable": 99999999999.0,
		"format": ScoreFormats.HEIGHT,
		"infinite_layers": true,
		"duration": 300.0 # 5 minutes
	},
	GameType.RACE_TO_RICHES: {
		"display_name": "Race to Riches",
		"score_key_set": "ss_race_to_riches",
		"score_key_random": "rs_race_to_riches",
		"higher_is_better": true,
		"min_reasonable": 0.0,
		"max_reasonable": INF,
		"format": ScoreFormats.MONEY,
		"infinite_layers": true,
		"duration": 600.0 # 10 minutes
	}
}


func get_score_key(game_type: GameType, seed_type: SeedType) -> String:
	var def = GAME_TYPE_DEFINITIONS.get(game_type, null)
	if def == null:
		return ""
	return def.get("score_key_set") if seed_type == SeedType.SET else def.get("score_key_random")

func is_score_higher_better(game_type: GameType) -> bool:
	var def = GAME_TYPE_DEFINITIONS.get(game_type, null)
	if def == null:
		return false
	return def.get("higher_is_better", false)

func get_game_display_name(game_type: GameType) -> String:
	var def = GAME_TYPE_DEFINITIONS.get(game_type, null)
	if def == null:
		return ""
	return def.get("display_name", "")

# Firebase Firestore constants
const FIRESTORE_COLLECTION := "leaderboard"
const PLAYER_NAME_KEY := "player_name"
const SCORES_KEY := "scores"

# Firestore operation timeouts and retries
const FIRESTORE_TIMEOUT_MS := 15000 # 15 seconds
const MAX_RETRY_ATTEMPTS := 3
const INITIAL_RETRY_DELAY_MS := 1000 # 1 second, doubles on each retry

# Upload cooldown and validation
const UPLOAD_COOLDOWN_SECONDS := 60 # 1 minute between uploads
const LAST_UPLOAD_TIMESTAMP_KEY := "last_upload_timestamp"
const MIN_USERNAME_LENGTH := 3
const MAX_USERNAME_LENGTH := 20

# Leaderboard caching
const LEADERBOARD_CACHE_TTL_SECONDS := 60 # 1 minute cache duration
var _leaderboard_cache: Array = []
var _leaderboard_cache_timestamp: int = 0

# Score validation bounds
# TODO: make gamemode specific reasonable bounds
const MIN_REASONABLE_SCORE := 0.0
const MAX_REASONABLE_SCORE := 99999999

var fps_visible: bool = false
var fps_message_timer: Timer

var tutorial_session_active: bool = false

# Caching for ConfigFiles to avoid repeated disk reads
var _settings_cache: ConfigFile
var _player_data_cache: ConfigFile
var _cache_valid: bool = false

# Profanity set for O(1) username validation (converted from array for performance)
var _profanity_set: Dictionary = {}

# Profanity list for username validation
var profanity_list: Array[String] = [
	"fuck",
	"bugger",
	"slag",
	"nonce",
	"shitlord",
	"fucknut",
	"fuckstick",
	"fucktard",
	"shitwit",
	"shitnugget",
	"shitbucket",
	"shitmouse",
	"shitgoblin",
	"shitrat",
	"shitlips",
	"shitmouth",
	"shitbreath",
	"shitwhistle",
	"shitpickle",
	"fuckbucket",
	"fuckbiscuit",
	"fucknugget",
	"fuckstain",
	"fuckbrain",
	"fuckmonster",
	"fuckpig",
	"fuckmuppet",
	"fucktoy",
	"shitferret",
	"shitgargler",
	"shitcunt",
	"shitcock",
	"shitdick",
	"shitfucker",
	"pissflap",
	"pissgoblin",
	"pissstain",
	"wankstain",
	"wankface",
	"wankmaggot",
	"wanklord",
	"wanksock",
	"jerkwad",
	"jerkface",
	"slagbag",
	"slimeball",
	"scumbag",
	"scumlord",
	"filthbag",
	"trashhuman",
	"trashplayer",
	"wannabe",
	"sweatl0rd",
	"nolifer",
	"nolife",
	"virgin",
	"incel",
	"simp",
	"cuck",
	"cuckold",
	"snowflake",
	"crybaby",
	"attentionwhore",
	"ragequit",
	"ragequitter",
	"wannabegod",
	"wannabetryhard",
	"tryhardshit",
	"nigger",
	"nigga",
	"hardr",
	"spic",
	"kike",
	"wetback",
	"chink",
	"gook",
	"raghead",
	"sandnigger",
	"beaner",
	"paki",
	"coon",
	"porchmonkey",
	"cracker",
	"honky",
	"faggot",
	"tranny",
	"dyke",
	"retard",
	"mongoloid",
	"heilhitler",
	"siegheil",
	"naziscum",
	"whitepower",
	"killall",
	"racewar",
	"lynch",
	"tits",
	"boobs",
	"penis",
]

# Firebase references
var firebase_auth: FirebaseAuth
var firestore: FirebaseFirestore
var is_authenticated: bool = false
var _auth_signal_received: bool = false

func _ready() -> void:
	_setup_fps_timer()
	_init_profanity_set()
	_init_firebase()
	
	fps_visible = load_setting(UI_SECTION, FPS_COUNTER_KEY, false)
	if fps_visible:
		fps_message_timer.start(0.1)
	
	# Download personal records from Firebase on startup
	if is_instance_valid(self ):
		await download_personal_records_from_firebase()

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
	# Load or use cached config
	if _settings_cache == null:
		_settings_cache = ConfigFile.new()
		_settings_cache.load(SETTINGS_PATH)
	var config := _settings_cache
	
	# Ensure version is set
	if not config.has_section_key("meta", "version"):
		config.set_value("meta", "version", DATA_VERSION)
	config.set_value(section, key, value)
	
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save setting: %s/%s" % [section, key])
	else:
		_cache_valid = true

func load_setting(section: String, key: String, default_value: Variant) -> Variant:
	"""Load a setting from the game settings file (uses cache)"""
	# Load or use cached config
	if _settings_cache == null:
		_settings_cache = ConfigFile.new()
		var err := _settings_cache.load(SETTINGS_PATH)
		if err != OK:
			return default_value
	
	return _settings_cache.get_value(section, key, default_value)

func has_setting(section: String, key: String) -> bool:
	"""Check if a setting exists (uses cache)"""
	# Load or use cached config
	if _settings_cache == null:
		_settings_cache = ConfigFile.new()
		var err := _settings_cache.load(SETTINGS_PATH)
		if err != OK:
			return false
	
	return _settings_cache.has_section_key(section, key)


func intify(text) -> int:
	if typeof(text) == TYPE_INT:
		return text
	var result: int = 0
	for charr in text:
		result += ord(charr)
	return result

func _init_profanity_set() -> void:
	"""Initialize profanity set from array for O(1) lookup performance"""
	_profanity_set.clear()
	for word in profanity_list:
		_profanity_set[word.to_lower()] = true

func _reload_config_cache() -> void:
	"""Clear config file caches to force reload from disk"""
	_settings_cache = null
	_player_data_cache = null
	_cache_valid = false

# Player Data Management

func _calculate_checksum(records: Dictionary) -> String:
	"""Calculate a checksum for personal records to detect tampering.
	Sorts keys to ensure deterministic hash regardless of iteration order."""
	var keys = records.keys()
	keys.sort()

	# Build a sorted string representation (deterministic)
	var sorted_str := "{"
	for i in range(keys.size()):
		var key = keys[i]
		var value = records[key]
		sorted_str += "\"%s\": %s" % [key, _checksum_value_to_string(value)]
		if i < keys.size() - 1:
			sorted_str += ", "
	sorted_str += "}"

	# Compute a deterministic 32-bit FNV-1a hash of the string and return hex
	# Use 32-bit variant so values fit in GDScript signed ints reliably
	var data: PackedByteArray = sorted_str.to_utf8_buffer()
	var fnv_offset := 2166136261
	var fnv_prime := 16777619
	var h := fnv_offset
	for b in data:
		h = (h ^ int(b)) & 0xFFFFFFFF
		h = (h * fnv_prime) & 0xFFFFFFFF

	# Format as zero-padded 8-char hex string for stable storage
	var hex_str := String("%08x") % [h]
	return hex_str

func _checksum_value_to_string(value: Variant) -> String:
	if value == null:
		return "null"

	match typeof(value):
		TYPE_FLOAT:
			if value == INF:
				return "inf"
			if value == -INF:
				return "-inf"
			if value != value:
				return "nan"
			return var_to_str(value)
		TYPE_DICTIONARY:
			var dict := value as Dictionary
			var keys := dict.keys()
			keys.sort()
			var parts: Array[String] = []
			for key in keys:
				parts.append("\"%s\": %s" % [str(key), _checksum_value_to_string(dict[key])])
			return "{" + ", ".join(parts) + "}"
		TYPE_ARRAY:
			var array := value as Array
			var parts: Array[String] = []
			for item in array:
				parts.append(_checksum_value_to_string(item))
			return "[" + ", ".join(parts) + "]"
		TYPE_STRING:
			return JSON.stringify(value)
		_:
			return str(value)

func _get_all_personal_records() -> Dictionary:
	"""Get all personal records as a dictionary: {game_type:seed_type: time}
	Verifies checksum to detect tampering. Resets records if tampering is detected."""
	var records = load_player_data(PLAYER_SECTION, PERSONAL_RECORD_KEY, {})
	if not records is Dictionary:
		records = {}
	
	# Verify checksum to detect tampering
	var stored_checksum = load_player_data(PLAYER_SECTION, "checksum", "")
	var calculated_checksum = _calculate_checksum(records)
	
	if stored_checksum != "" and stored_checksum != calculated_checksum:
		push_error("Personal records have been tampered with!: stored checksum %s does not match calculated checksum %s" % [stored_checksum, calculated_checksum])
		Manager.message.info("[pulse color=red]Save file appears to be modified. Records reset.", 15.0)
		records = {}
	
	# Ensure all game type + seed type combinations exist using centralized definitions
	for game_type in GameType.values():
		for seed_type in SeedType.values():
			var key: Array[int] = [game_type, seed_type]
			if not records.has(key):
				# Default depends on whether higher score is better for this mode
				records[key] = 0.0 if is_score_higher_better(game_type) else INF
	return records

func _save_all_personal_records(records: Dictionary) -> void:
	"""Save all personal records with checksum for tamper detection"""
	save_player_data(PLAYER_SECTION, PERSONAL_RECORD_KEY, records)
	
	# Add checksum to detect tampering
	var checksum = _calculate_checksum(records)
	save_player_data(PLAYER_SECTION, "checksum", checksum)

func get_current_seed_type() -> SeedType:
	"""Determine the current seed type based on world state.
	Returns SeedType.SET if a seed was explicitly provided, SeedType.RANDOM otherwise."""
	if not is_instance_valid(World.main):
		return SeedType.RANDOM
	return World.main.seed_type_used as SeedType

func contains_profanity(text: String) -> bool:
	"""Check if text contains any profanity from the profanity set.
	Case-insensitive check using O(1) set lookup. Returns true if profanity is found."""
	if _profanity_set.is_empty():
		_init_profanity_set()
	
	var text_lower = text.to_lower()
	
	# Split into words and check each one
	var words = text_lower.split(" ")
	for word in words:
		# Also check substrings for words containing profanity
		if word in _profanity_set:
			print("Profanity detected in word '%s'" % word)
			return true
		# Check if profanity is contained as substring
		for profanity_word in _profanity_set.keys():
			if profanity_word in word:
				print("Profanity detected in word '%s': contains '%s'" % [word, profanity_word])
				return true
	
	return false

func get_personal_record(game_type: GameType, seed_type: SeedType) -> float:
	"""Get the player's personal best time for a specific game type and seed type.
	If game_type is empty, uses current game type.
	If seed_type is empty, uses current seed type.
	Returns INF for normal/infinite (lower is better), 0.0 for infinite_rising_lava (higher is better)."""
	var key: Array[int] = [game_type, seed_type]
	var records = _get_all_personal_records()
	if not records.has(key):
		return 0.0 if is_score_higher_better(game_type) else INF
	return records[key]

func set_personal_record(value: float, game_type: GameType, seed_type: SeedType) -> void:
	"""Update the personal record for a specific game type and seed type if the new time is better.
	If game_type is empty, uses current game type.
	If seed_type is empty, uses current seed type.
	For normal/infinite: lower time is better. For infinite_rising_lava: higher time is better.
	Also uploads the updated records to Firebase."""
	
	var key: Array[int] = [game_type, seed_type]
	var records = _get_all_personal_records()
	var current_record = records.get(key, 0.0 if is_score_higher_better(game_type) else INF)

	# Determine if this is a new record using centralized rule
	var is_new_record = false
	if is_score_higher_better(game_type):
		is_new_record = value > current_record
	else:
		is_new_record = value < current_record
	
	if is_new_record:
		records[key] = value
		_save_all_personal_records(records)
		personal_record_updated.emit(value, game_type)

func get_all_personal_records() -> Dictionary:
	"""Get all personal records for all game types"""
	return _get_all_personal_records()

func save_player_data(section: String, key: String, value: Variant) -> void:
	"""Save player data to the player data file"""
	# Load or use cached config
	if _player_data_cache == null:
		_player_data_cache = ConfigFile.new()
		_player_data_cache.load(PLAYER_DATA_PATH)
	var config := _player_data_cache
	
	# Ensure version is set
	if not config.has_section_key("meta", "version"):
		config.set_value("meta", "version", DATA_VERSION)
	config.set_value(section, key, value)
	
	var err := config.save(PLAYER_DATA_PATH)
	if err != OK:
		push_error("Failed to save player data: %s/%s" % [section, key])
	else:
		_cache_valid = true

func load_player_data(section: String, key: String, default_value: Variant) -> Variant:
	"""Load player data from the player data file (uses cache)"""
	# Load or use cached config
	if _player_data_cache == null:
		_player_data_cache = ConfigFile.new()
		var err := _player_data_cache.load(PLAYER_DATA_PATH)
		if err != OK:
			return default_value
	
	return _player_data_cache.get_value(section, key, default_value)

func has_player_data(section: String, key: String) -> bool:
	"""Check if player data exists (uses cache)"""
	# Load or use cached config
	if _player_data_cache == null:
		_player_data_cache = ConfigFile.new()
		var err := _player_data_cache.load(PLAYER_DATA_PATH)
		if err != OK:
			return false
	
	return _player_data_cache.has_section_key(section, key)

func clear_player_data() -> void:
	"""Clear all player data"""
	var config := ConfigFile.new()
	config.load(PLAYER_DATA_PATH)
	config.clear()
	config.save(PLAYER_DATA_PATH)
	_reload_config_cache() # Clear caches after clearing data
	Manager.message.info(" All player data cleared. Restart the game to use online features again.")

func clear_player_data_from_firebase() -> void:
	"""Clear player data from Firebase Firestore and delete the anonymous account"""
	if not is_authenticated:
		Manager.message.info("Not connected. Cannot clear online data.")
		return
	
	var player_id = _get_player_id()
	if player_id == "":
		Manager.message.info("No player ID available.")
		return
	
	# Delete player document from Firestore
	var collection = firestore.collection(FIRESTORE_COLLECTION)
	var doc = await collection.get_doc(player_id)
	
	if doc != null:
		var was_deleted = await collection.delete(doc)
		if was_deleted:
			Manager.message.info("Online data cleared.")
		else:
			Manager.message.info("Failed to clear online data.")
	else:
		Manager.message.info("No online data to clear.")
	
	# Delete the anonymous account from Firebase Auth
	if firebase_auth:
		firebase_auth.delete_user_account()
		Manager.message.info("Online account deleted.")
		is_authenticated = false
		# Clear saved account ID for next session
		_save_account_id("")


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


# Firebase Leaderboard Management

func _init_firebase() -> void:
	"""Initialize Firebase references"""
	firebase_auth = Firebase.Auth
	firestore = Firebase.Firestore
	
	# Connect to auth signals
	if firebase_auth:
		firebase_auth.signup_succeeded.connect(_on_auth_signup_succeeded)
		firebase_auth.signup_failed.connect(_on_auth_signup_failed)
	
	# Attempt anonymous authentication on startup
	if not is_authenticated:
		authenticate_anonymous()

func authenticate_anonymous() -> void:
	"""Authenticate user anonymously with Firebase"""
	if firebase_auth == null:
		push_error("Firebase Auth not initialized")
		Manager.message.info("Online features not initialized.")
		return
	
	# Try to restore previous anonymous session from encrypted auth file
	if firebase_auth.check_auth_file():
		var success = firebase_auth.load_auth()
		if success:
			is_authenticated = true
			return
		else:
			Manager.message.info("Failed to load saved account.")

	# No saved session, create new anonymous account
	Manager.message.info("Connecting to online services...")
	_auth_signal_received = false
	firebase_auth.login_anonymous()
	
	# Wait for auth signal with timeout
	var timeout = 0
	while not _auth_signal_received and timeout < 50: # ~5 second timeout
		await get_tree().process_frame
		timeout += 1
	
	if timeout >= 50:
		push_error("Firebase authentication timed out")
		Manager.message.info("Connection timed out. Check your internet.")

func _get_player_id() -> String:
	"""Get the current authenticated player's UID"""
	if firebase_auth and firebase_auth.auth.get("localid"):
		return firebase_auth.auth.get("localid", "")
	return ""

func _on_auth_signup_succeeded(auth_info: Dictionary) -> void:
	"""Called when Firebase authentication succeeds"""
	_auth_signal_received = true
	is_authenticated = true
	var player_id = auth_info.get("localid", "Unknown")
	Manager.message.info("Successfully connected to online services")
	# Save credentials to encrypted file for persistence across sessions
	firebase_auth.save_auth(firebase_auth.auth)
	_save_account_id(player_id)


func _on_auth_signup_failed(error_code: int, message: String) -> void:
	"""Called when Firebase authentication fails"""
	_auth_signal_received = true
	is_authenticated = false
	push_error("Firebase Auth Failed - Code: %d, Message: %s" % [error_code, message])
	
	# Provide helpful error messages based on error code
	if error_code == 400:
		Manager.message.info("Anonymous login not enabled. Check your project settings.")
	elif "NETWORK" in message or "Connection" in message:
		Manager.message.info("Network error. Check your internet connection.")
	else:
		Manager.message.info("Failed to connect: %s" % message)

func _save_account_id(player_id: String) -> void:
	"""Save account ID for persistence across game sessions"""
	save_player_data("firebase", "account_id", player_id)

func _get_saved_account_id() -> String:
	"""Retrieve the saved account ID from previous sessions"""
	return load_player_data("firebase", "account_id", "")


func _get_leaderboard_key(game_type: GameType, seed_type: SeedType) -> String:
	"""Convert internal game type + seed type to leaderboard key format
	Format: ss_<gamemode> (set seed) or rs_<gamemode> (random seed)"""
	return get_score_key(game_type, seed_type)

func download_personal_records_from_firebase() -> void:
	"""Download personal records from Firebase and merge with local records.
	Uses Firebase records as source of truth where available."""
	if not is_authenticated:
		print("Not authenticated. Skipping Firebase download.")
		return
	
	var player_id = _get_player_id()
	if player_id == "":
		print("No player ID available. Skipping Firebase download.")
		return
	
	var collection = firestore.collection(FIRESTORE_COLLECTION)
	var doc = await collection.get_doc(player_id)
	
	if doc == null:
		print("No existing Firebase record for player. Using local records.")
		return
	
	# Extract scores from Firebase document
	var firebase_scores: Dictionary = {}
	if doc.has_method("get_value"):
		var scores_value = doc.get_value(SCORES_KEY)
		if scores_value is Dictionary:
			for score_key in scores_value:
				var score = scores_value[score_key]
				if typeof(score) == TYPE_NIL:
					if score_key.contains("lava"):
						firebase_scores[score_key] = 0.0
					else:
						firebase_scores[score_key] = INF
				elif typeof(score) == TYPE_FLOAT or typeof(score) == TYPE_INT:
					firebase_scores[score_key] = score
	
	# Convert Firebase format to internal format and merge
	var local_records = _get_all_personal_records()
	var merged_records = local_records.duplicate()
	
	for firebase_key in firebase_scores:
		# Convert Firebase key format (ss_classic) to internal format [normal,set]
		var internal_key = _convert_firebase_key_to_internal(firebase_key)
		if internal_key != [-1, -1]:
			var firebase_value = firebase_scores[firebase_key]
			var local_value = local_records.get(internal_key, INF)
			
			# Use Firebase value as source of truth if it's better
			var game_type: int = int(internal_key[0])
			if is_score_higher_better(game_type):
				# For modes where higher is better
				if firebase_value > local_value:
					merged_records[internal_key] = firebase_value
			else:
				# For modes where lower is better
				if firebase_value < local_value:
					merged_records[internal_key] = firebase_value
	
	# Save merged records locally
	_save_all_personal_records(merged_records)

func _convert_firebase_key_to_internal(firebase_key: String) -> Array[int]:
	"""Convert Firebase leaderboard key format to internal game_type:seed_type format.
	Example: 'ss_classic' -> 'normal:set', 'rs_infinite' -> 'infinite:random'"""
	var parts = firebase_key.split("_", false)
	if parts.size() != 2:
		return [-1, -1]

	# Reverse lookup in definitions to find matching game type
	for game_type_key in GameType.values():
		var def = GAME_TYPE_DEFINITIONS[game_type_key]
		if def.get("score_key_set", "") == firebase_key:
			return [game_type_key, SeedType.SET]
		if def.get("score_key_random", "") == firebase_key:
			return [game_type_key, SeedType.RANDOM]

	return [-1, -1]

func _validate_score(score, game_type: String) -> bool:
	"""Validate that a score is within reasonable bounds
	Accepts the leaderboard key (like 'ss_classic' or 'rs_lava') to determine if 0.0 is acceptable
	Returns true if score is valid, false otherwise"""
	# Handle null values (unfinished games)
	if score == null:
		return true
	
	# Check for infinity (represented as float)
	if score == INF or score == -INF:
		return true
	
	# Convert to float if needed (could be string from config file)
	var float_score: float
	if score is String:
		var score_str = score.to_lower()
		# String representation of infinity is valid
		if "inf" in score_str:
			return true
		# Try to parse as float
		float_score = float(score)
	else:
		float_score = score
	
	# Handle infinity after conversion
	if float_score == INF or float_score == -INF:
		return true
	
	# Try to map the provided leaderboard key (like 'ss_classic') to internal game_type
	var internal = _convert_firebase_key_to_internal(game_type)
	if internal != [-1, -1]:
		var gt = internal[0]
		var def = GAME_TYPE_DEFINITIONS.get(gt, null)
		if def != null:
			# If higher-is-better mode, allow 0.0 as the 'no-score' default
			if def.get("higher_is_better", false) and float_score == 0.0:
				return true
			# Use per-type bounds if provided
			var min_b = def.get("min_reasonable", MIN_REASONABLE_SCORE)
			var max_b = def.get("max_reasonable", MAX_REASONABLE_SCORE)
			if float_score < min_b:
				print("Score too low: %f (key: %s, string: %s)" % [float_score, game_type, str(score)])
				return false
			if float_score > max_b:
				print("Score too high: %f (key: %s, string: %s)" % [float_score, game_type, str(score)])
				return false
			return true
	# Fallback to global numeric bounds
	if float_score < MIN_REASONABLE_SCORE:
		print("Score too low: %f (key: %s, string: %s)" % [float_score, game_type, str(score)])
		return false
	if float_score > MAX_REASONABLE_SCORE:
		print("Score too high: %f (key: %s, string: %s)" % [float_score, game_type, str(score)])
		return false
	return true

func _validate_scores_dictionary(scores: Dictionary) -> bool:
	"""Validate all scores in a dictionary
	Returns true if all scores are valid"""
	for key in scores:
		var score = scores[key]
		if not _validate_score(score, key):
			return false
	return true

func _validate_game_mode(game_type: GameType, seed_type: SeedType) -> bool:
	"""Validate that game_type and seed_type are valid enums"""
	var valid_game_types = GameType.values()
	var valid_seed_types = SeedType.values()
	return game_type in valid_game_types and seed_type in valid_seed_types

func _sanitize_username(username: String) -> String:
	"""Sanitize and validate username
	Returns sanitized username or empty string if invalid"""
	# Trim whitespace
	var sanitized = username.strip_edges()
	
	# Check length
	print("Sanitized username: '%s' (length: %d)" % [sanitized, sanitized.length()])
	if sanitized.length() < MIN_USERNAME_LENGTH:
		Manager.message.info("Username must be at least %d characters." % MIN_USERNAME_LENGTH)
		return ""
	
	if sanitized.length() > MAX_USERNAME_LENGTH:
		Manager.message.info("Username must not exceed %d characters." % MAX_USERNAME_LENGTH)
		return ""
	
	# Only allow alphanumeric, spaces, hyphens, and underscores
	var valid_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_"
	for char in sanitized:
		if not char in valid_chars:
			Manager.message.info("Username contains invalid characters. Use only letters, numbers, spaces, hyphens, and underscores.")
			return ""
	
	return sanitized

func _check_upload_cooldown() -> bool:
	"""Check if enough time has passed since last upload
	Returns true if cooldown has expired, false if still on cooldown"""
	var last_upload = load_setting(PLAYER_SECTION, LAST_UPLOAD_TIMESTAMP_KEY, 0)
	var current_time = Time.get_unix_time_from_system()
	var time_since_upload = current_time - last_upload
	
	if time_since_upload < UPLOAD_COOLDOWN_SECONDS:
		var wait_time = UPLOAD_COOLDOWN_SECONDS - time_since_upload
		Manager.message.info("Please wait %d seconds before uploading again." % int(wait_time))
		return false
	
	return true

func _update_last_upload_timestamp() -> void:
	"""Update the last upload timestamp in player settings"""
	var current_time = Time.get_unix_time_from_system()
	save_setting(PLAYER_SECTION, LAST_UPLOAD_TIMESTAMP_KEY, current_time)

func _is_leaderboard_cache_valid() -> bool:
	"""Check if cached leaderboard data is still fresh"""
	var current_time = Time.get_unix_time_from_system()
	return _leaderboard_cache.size() > 0 and (current_time - _leaderboard_cache_timestamp) < LEADERBOARD_CACHE_TTL_SECONDS

func _clear_leaderboard_cache() -> void:
	"""Clear the leaderboard cache"""
	_leaderboard_cache.clear()
	_leaderboard_cache_timestamp = 0

func _firestore_operation_with_timeout_and_retry(operation: Callable, operation_name: String = "Firestore operation", failure_message: String = "") -> Variant:
	"""Execute a Firestore operation with timeout and retry logic.
	Properly handles timeout by creating a wrapper that can be abandoned.
	Returns the result or null if failed after all retries"""
	var attempt = 0
	var delay_ms = INITIAL_RETRY_DELAY_MS
	
	while attempt < MAX_RETRY_ATTEMPTS:
		attempt += 1
		print("Attempting %s (attempt %d/%d)" % [operation_name, attempt, MAX_RETRY_ATTEMPTS])
		
		var timeout_occurred = false
		var timeout_timer = get_tree().create_timer(FIRESTORE_TIMEOUT_MS / 1000.0)
		
		# Execute the operation and race it against timeout
		var operation_task = await operation.call()
		
		# Create timeout handler
		var timeout_handler = func():
			timeout_occurred = true
			print("Timeout on %s" % operation_name)
		
		# Wait for either the operation or timeout, whichever comes first
		var timeout_signal = timeout_timer.timeout
		timeout_signal.connect(timeout_handler)
		
		var result = await operation_task
		
		# Disconnect timeout if operation completed first
		if timeout_signal.is_connected(timeout_handler):
			timeout_signal.disconnect(timeout_handler)
		
		if not timeout_occurred and result != null:
			print("%s completed successfully" % operation_name)
			return result
		
		# Retry with exponential backoff (except on last attempt)
		if attempt < MAX_RETRY_ATTEMPTS:
			print("Retrying %s after %dms..." % [operation_name, delay_ms])
			Manager.message.info("Attempt failed. Retrying...")
			await get_tree().create_timer(delay_ms / 1000.0).timeout
			delay_ms *= 2
	
	print("Failed %s after %d attempts" % [operation_name, MAX_RETRY_ATTEMPTS])
	if failure_message != "":
		Manager.message.info(failure_message)
	return null

func _get_firestore_game_data() -> Dictionary:
	"""Fetch the current game version and release information from Firestore
	Returns a dictionary with version and release information or null if unable to retrieve"""
	if not is_authenticated:
		return {}

	var game_collection = firestore.collection("game")
	var game_doc = await game_collection.get_doc("data")
	
	if game_doc:
		var version = game_doc.get_value("data_version")
		# var release = game_doc.get_value("latest_release")
		# var messages = messages_for_this_version(game_doc)
		# var patch_notes = game_doc.get_value("releases_in_order")
		if version != null: # and release != null:
			return {"data_version": version} # , "latest_release": release, "messages": messages, "patch_notes": patch_notes}
	
	return {}

# func messages_for_this_version(game_doc) -> Array:
# 	"""Check if there are any messages in the game document that should be shown to the player based on their current version and last seen message timestamp"""
# 	var messages = []
# 	if not game_doc.get_value("messages"):
# 		return messages
	
# 	var all_messages: Dictionary = game_doc.get_value("messages")
# 	for key in all_messages:
# 		# key example: "1.0.0-1.0.2,1.0.4", would apply to versions 1.0.0 through 1.0.2 and 1.0.4
# 		var sections = key.split(",")
# 		for section in sections:
# 			var limits = section.split("-")
# 			if limits.size() == 2:
# 				var lower = limits[0].strip_edges()
# 				var upper = limits[1].strip_edges()
# 				if _is_version_in_range(GAME_VERSION, lower, upper):
# 					messages.append(all_messages[key])
# 			elif limits.size() == 1:
# 				var version = limits[0].strip_edges()
# 				if version == GAME_VERSION:
# 					messages.append(all_messages[key])
# 	return messages

func _is_version_in_range(version: String, lower: String, upper: String) -> bool:
	"""Check if a version string is within a specified range (inclusive)
	Version strings are expected in format 'major.minor.patch'"""
	var version_parts = version.split(".")
	var lower_parts = lower.split(".")
	var upper_parts = upper.split(".")
	
	for i in range(3): # Compare major, minor, patch
		var v = int(version_parts[i]) if i < version_parts.size() else 0
		var l = int(lower_parts[i]) if i < lower_parts.size() else 0
		var u = int(upper_parts[i]) if i < upper_parts.size() else 0
		
		if v < l:
			return false
		if v > u:
			return false
	
	return true

func _username_exists_in_leaderboard(username: String) -> bool:
	"""Check if a username already exists in the leaderboard
	Returns true if username is taken, false otherwise"""
	var leaderboard = await download_leaderboard(false)
	if not leaderboard is Array:
		return false
	
	for entry in leaderboard:
		if entry.has(PLAYER_NAME_KEY):
			var existing_name = entry[PLAYER_NAME_KEY]
			if existing_name.to_lower() == username.to_lower():
				return true
	
	return false

func upload_scores(player_name: String) -> bool:
	"""Upload all personal records to Firebase Firestore leaderboard
	Returns true if successful, false otherwise"""
	if Manager.dev_mode:
		Manager.message.info("Dev mode active - skipping score upload.")
		return false
	if not is_authenticated:
		Manager.message.info("Not authenticated. Cannot upload scores.")
		return false
	
	# Sanitize and validate username
	var sanitized_name = _sanitize_username(player_name)
	if sanitized_name == "":
		return false
	
	# Check upload cooldown
	if not _check_upload_cooldown():
		return false
	
	# Check game version before uploading
	var game_data = await _get_firestore_game_data()
	if game_data != {} and game_data["data_version"] != DATA_VERSION:
		Manager.message.info("A new game version is available. Please update to the latest version before uploading scores.")
		return false
	
	# Check for profanity in username
	if contains_profanity(sanitized_name):
		Manager.message.info("Username contains inappropriate content. Please change your username and try again.")
		return false
	
	# Check if username already exists (only if it's different from the player's current username)
	var current_username = load_player_data(PLAYER_SECTION, "current_username", "")
	if sanitized_name != current_username and await _username_exists_in_leaderboard(sanitized_name):
		Manager.message.info("Username already taken. Please choose a different username.")
		return false
	var player_id = _get_player_id()
	if player_id == "":
		Manager.message.info("No player ID available. Try again later.")
		return false
	
	# Prepare scores dictionary
	var scores: Dictionary = {}
	var records = _get_all_personal_records()
	
	# Convert internal record keys to leaderboard format and validate
	for record_key in records:
		if record_key.size() == 2:
			var game_type = record_key[0]
			var seed_type = record_key[1]

			# Validate game mode
			if not _validate_game_mode(game_type, seed_type):
				print("Invalid game mode: %s:%s" % [game_type, seed_type])
				continue
			
			var leaderboard_key = _get_leaderboard_key(game_type, seed_type)
			if leaderboard_key != "":
				var score_value = records[record_key]
				
				# Validate score (this handles various INF representations)
				if not _validate_score(score_value, leaderboard_key):
					print("Invalid score for %s: %s (type: %s)" % [leaderboard_key, score_value, typeof(score_value)])
					Manager.message.info("Invalid score detected. Upload cancelled.")
					return false
				
				# Normalize and convert score for Firestore
				# Convert various representations of infinity to null (Firestore doesn't support infinity)
				var normalized_score = score_value
				if score_value is String:
					if "inf" in score_value.to_lower():
						normalized_score = null
					else:
						normalized_score = float(score_value)
				elif score_value == INF or score_value == -INF:
					normalized_score = null
				
				scores[leaderboard_key] = normalized_score
	
	# Final validation of entire scores dictionary
	if not _validate_scores_dictionary(scores):
		Manager.message.info("Invalid scores detected. Upload cancelled.")
		return false
		
	# Prepare player data for Firestore
	var player_data = {
		PLAYER_NAME_KEY: sanitized_name,
		SCORES_KEY: scores,
		"version": DATA_VERSION,
	}
	
	# Upload to Firestore with timeout and retry
	var upload_operation = func():
		var collection = firestore.collection(FIRESTORE_COLLECTION)
		# Delete existing document if it exists, then add fresh one
		var existing_doc = await collection.get_doc(player_id)
		if existing_doc != null:
			await collection.delete(existing_doc)
		return await collection.add(player_id, player_data)
	var result = await _firestore_operation_with_timeout_and_retry(
		upload_operation,
		"Score upload",
		"No internet connection. Unable to upload scores right now."
	)
	
	if result:
		_update_last_upload_timestamp()
		_clear_leaderboard_cache() # Clear cache so fresh data is fetched
		# Save the username so we don't check for duplicates on future uploads
		save_player_data(PLAYER_SECTION, "current_username", sanitized_name)
		Manager.message.info("Scores uploaded successfully!")
		return true
	else:
		Manager.message.info("Failed to upload scores to Firestore. Please check your connection and try again.")
		return false

func download_leaderboard(messaging: bool = true) -> Variant:
	"""Download leaderboard data from Firebase Firestore (cached for 5 minutes)
	Returns array of player entries with format:
	[{\"player_name\": String, \"scores\": {ss_classic, rs_classic, ...}}, ...]
	Limited to top 100 entries for performance"""
	if not is_authenticated:
		if messaging:
			Manager.message.info("Not authenticated. Cannot download leaderboard.")
		return null
	
	# Check cache first
	if _is_leaderboard_cache_valid():
		print("Using cached leaderboard data (age: %ds)" % (Time.get_unix_time_from_system() - _leaderboard_cache_timestamp))
		if messaging:
			Manager.message.info("Please wait %d seconds before refreshing leaderboard again." % int(LEADERBOARD_CACHE_TTL_SECONDS - (Time.get_unix_time_from_system() - _leaderboard_cache_timestamp)))
		return _leaderboard_cache
	
	print("Leaderboard cache invalid or empty, fetching fresh data...")
	
	# Create the query operation
	var query_operation = func():
		var query: FirestoreQuery = FirestoreQuery.new()
		query.from(FIRESTORE_COLLECTION)
		query.where("version", FirestoreQuery.OPERATOR.EQUAL, DATA_VERSION)
		query.order_by("player_name", FirestoreQuery.DIRECTION.DESCENDING)
		query.limit(100) # Limit to top 100 entries
		
		# Set up error handler to capture the actual error
		var firestore_error = null
		var on_firestore_error = func(error_result):
			firestore_error = error_result
			print("Firestore query error details: ", error_result)
		
		Firebase.Firestore.error.connect(on_firestore_error)
		
		# Execute the query
		var results = await Firebase.Firestore.query(query)
		
		# Keep the signal connected briefly to catch delayed errors
		await get_tree().process_frame
		Firebase.Firestore.error.disconnect(on_firestore_error)
		
		if firestore_error:
			print("Firestore query error: %s" % str(firestore_error))
			return null
		
		return results
	
	# Execute with timeout and retry
	var results = await _firestore_operation_with_timeout_and_retry(
		query_operation,
		"Leaderboard download",
		"No internet connection. Leaderboard is unavailable right now."
	)
	if results == null:
		return null
	
	var leaderboard_entries: Array = []
	
	if results is Array and results.size() > 0:
		# Process each player document
		for doc in results:
			# Get keys from the document
			var doc_keys = doc.keys() if doc.has_method("keys") else []
			
			# Check if this document has the required fields
			if not (PLAYER_NAME_KEY in doc_keys and SCORES_KEY in doc_keys):
				print("Skipping document - missing required fields. Keys: ", doc_keys)
				continue
			
			# Extract player name using get_value method
			var player_name = ""
			if doc.has_method("get_value"):
				var player_name_value = doc.get_value(PLAYER_NAME_KEY)
				if player_name_value is Dictionary and player_name_value.has("stringValue"):
					player_name = player_name_value["stringValue"]
				else:
					player_name = str(player_name_value)
			
			# Extract scores from the document
			var scores: Dictionary = {}
			if doc.has_method("get_value"):
				var scores_value = doc.get_value(SCORES_KEY)
				if scores_value is Dictionary:
					for score_key in scores_value:
						var score = scores_value[score_key]
						if typeof(score) == TYPE_NIL:
							if score_key.contains("lava"):
								scores[score_key] = 0.0
							else:
								scores[score_key] = INF
						elif typeof(score) == TYPE_FLOAT or typeof(score) == TYPE_INT:
							scores[score_key] = score
						else:
							print("Unexpected score format for key %s: %s" % [score_key, score])
							continue
			# Only add entry if player name is not empty
			if not player_name.is_empty():
				var entry: Dictionary = {
					"player_name": player_name,
					"scores": scores
				}
				leaderboard_entries.append(entry)
	elif results is Array and results.size() == 0:
		print("Leaderboard is empty")
	else:
		print("Failed to fetch leaderboard data")
	
	# Update cache
	if leaderboard_entries.size() > 0:
		_leaderboard_cache = leaderboard_entries
		_leaderboard_cache_timestamp = Time.get_unix_time_from_system()
	
	return leaderboard_entries
