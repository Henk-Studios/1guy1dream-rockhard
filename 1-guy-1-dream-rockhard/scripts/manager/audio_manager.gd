## Manages all audio playback including music, sound effects, and volume control
extends Node
class_name AudioManager

@export var audio_properties: Dictionary[String, AudioProperties]

# Music player reference
var music_player: AudioStreamPlayer

# Music fade settings
const MUSIC_FADE_DURATION: float = 2.0
var music_fade_tween: Tween

# Sound effect players pool - available for reuse
var sfx_player_pool: Array[AudioStreamPlayer] = []
var sfx_3d_player_pool: Array[AudioStreamPlayer3D] = []

# Active sound effect players - currently playing
var active_sfx_players: Array[AudioStreamPlayer] = []
var active_sfx_3d_players: Array[AudioStreamPlayer3D] = []

# Looping SFX players pool (identified by string keys)
var looping_sfx_players: Dictionary[String, AudioStreamPlayer] = {}
var looping_sfx_3d_players: Dictionary[String, AudioStreamPlayer3D] = {}
var looping_sfx_keys: Dictionary[String, String] = {} # Maps loop_id to audio key
var looping_sfx_3d_keys: Dictionary[String, String] = {} # Maps loop_id to audio key

# Audio bus indices
var master_bus_index: int
var music_bus_index: int
var sfx_bus_index: int

# Pooling settings
const MAX_ACTIVE_PLAYERS: int = 40
const MAX_PLAYERS_PER_SOUND: int = 6

# Track active players per sound key
var sfx_per_key_count: Dictionary[String, int] = {}
var sfx_3d_per_key_count: Dictionary[String, int] = {}

func _ready() -> void:
	_setup_audio_buses()
	set_master_volume(0.5)
	set_music_volume(0.0)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"
	play_main_music()

func _setup_audio_buses() -> void:
	"""Setup audio buses for volume control"""
	# Get bus indices
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# Create Music and SFX buses if they don't exist
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")
		AudioServer.set_bus_send(1, "Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "SFX")
		AudioServer.set_bus_send(2, "Master")
	sfx_bus_index = AudioServer.get_bus_index("SFX")

# Pool Management Functions

func _get_sfx_player(key: String, force: bool = false) -> AudioStreamPlayer:
	"""Get an AudioStreamPlayer from the pool or create a new one.
	Returns null if limits are exceeded (unless force=true).
	"""
	# Check global limit
	if not force and len(active_sfx_players) >= MAX_ACTIVE_PLAYERS:
		print("Warning: Max active SFX players reached (%d). Ignoring request for: %s" % [MAX_ACTIVE_PLAYERS, key])
		return null
	
	# Check per-sound limit (always enforced)
	if sfx_per_key_count.get(key, 0) >= MAX_PLAYERS_PER_SOUND:
		print("Warning: Max players for sound '%s' reached (%d). Ignoring request." % [key, MAX_PLAYERS_PER_SOUND])
		return null
	
	# Get player from pool or create new one
	var player: AudioStreamPlayer
	if len(sfx_player_pool) > 0:
		player = sfx_player_pool.pop_back()
	else:
		player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
	
	# Track active player
	active_sfx_players.append(player)
	sfx_per_key_count[key] = sfx_per_key_count.get(key, 0) + 1
	
	return player

func _return_sfx_player(player: AudioStreamPlayer, key: String) -> void:
	"""Return an AudioStreamPlayer to the pool."""
	if player in active_sfx_players:
		active_sfx_players.erase(player)
	
	# Decrement per-sound count
	if key in sfx_per_key_count:
		sfx_per_key_count[key] -= 1
		if sfx_per_key_count[key] <= 0:
			sfx_per_key_count.erase(key)
	
	# Reset player state and return to pool
	player.stop()
	player.stream = null
	sfx_player_pool.append(player)

func _get_sfx_3d_player(key: String, force: bool = false) -> AudioStreamPlayer3D:
	"""Get an AudioStreamPlayer3D from the pool or create a new one.
	Returns null if limits are exceeded (unless force=true).
	"""
	# Check global limit
	if not force and len(active_sfx_3d_players) >= MAX_ACTIVE_PLAYERS:
		print("Warning: Max active 3D SFX players reached (%d). Ignoring request for: %s" % [MAX_ACTIVE_PLAYERS, key])
		return null
	
	# Check per-sound limit (always enforced)
	if sfx_3d_per_key_count.get(key, 0) >= MAX_PLAYERS_PER_SOUND:
		print("Warning: Max players for 3D sound '%s' reached (%d). Ignoring request." % [key, MAX_PLAYERS_PER_SOUND])
		return null
	
	# Get player from pool or create new one
	var player: AudioStreamPlayer3D
	if len(sfx_3d_player_pool) > 0:
		player = sfx_3d_player_pool.pop_back()
	else:
		player = AudioStreamPlayer3D.new()
		player.bus = "SFX"
		add_child(player)
	
	# Track active player
	active_sfx_3d_players.append(player)
	sfx_3d_per_key_count[key] = sfx_3d_per_key_count.get(key, 0) + 1
	
	return player

func _return_sfx_3d_player(player: AudioStreamPlayer3D, key: String) -> void:
	"""Return an AudioStreamPlayer3D to the pool."""
	if player in active_sfx_3d_players:
		active_sfx_3d_players.erase(player)
	
	# Decrement per-sound count
	if key in sfx_3d_per_key_count:
		sfx_3d_per_key_count[key] -= 1
		if sfx_3d_per_key_count[key] <= 0:
			sfx_3d_per_key_count.erase(key)
	
	# Reset player state and return to pool
	player.stop()
	player.stream = null
	sfx_3d_player_pool.append(player)

# Volume Control

func set_music_volume(volume: float) -> void:
	var volume_db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(music_bus_index, volume_db)

func set_master_volume(volume: float) -> void:
	var volume_db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(master_bus_index, volume_db)

func set_sfx_volume(volume: float) -> void:
	var volume_db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)

func get_master_volume() -> float:
	var volume_db = AudioServer.get_bus_volume_db(master_bus_index)
	return db_to_linear(volume_db)

func get_music_volume() -> float:
	var volume_db = AudioServer.get_bus_volume_db(music_bus_index)
	return db_to_linear(volume_db)

func get_sfx_volume() -> float:
	var volume_db = AudioServer.get_bus_volume_db(sfx_bus_index)
	return db_to_linear(volume_db)

# Music Management

func play_music(key: String, fade_out: bool = false) -> void:
	if not audio_properties.has(key):
		print("Warning: No audio for key ", key)
		return
	
	var props = audio_properties[key]
	if not props.stream:
		print("Warning: No audio stream for ", key)
		return
	
	if fade_out and music_player.playing:
		# Fade out current music before switching
		await fade_out_music()
	
	music_player.stream = props.stream
	music_player.volume_db = linear_to_db(props.volume)
	music_player.play()
	await music_player.finished

func pause_music() -> void:
	if music_player and music_player.playing:
		music_player.stream_paused = true

func resume_music() -> void:
	if music_player and music_player.stream_paused:
		music_player.stream_paused = false

func stop_music() -> void:
	if music_player:
		music_player.stop()

func fade_out_music() -> void:
	if not music_player or not music_player.playing:
		return
	
	# Cancel any existing fade tween
	if music_fade_tween:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", -80.0, MUSIC_FADE_DURATION)
	await music_fade_tween.finished
	music_player.stop()

func is_music_playing() -> bool:
	return music_player and music_player.playing and not music_player.stream_paused

# Sound Effects Management

func play_sfx(key: String, force: bool = false, pitch_scale: float = 1.0) -> void:
	if not audio_properties.has(key):
		print("Warning: No audio for key ", key)
		return
	
	var props = audio_properties[key]
	if not props.stream:
		print("Warning: No audio stream for ", key)
		return
	
	var player = _get_sfx_player(key, force)
	if not player:
		return
	
	player.stream = props.stream
	player.volume_db = linear_to_db(props.volume)
	player.pitch_scale = pitch_scale
	player.finished.connect(_on_sfx_finished.bind(player, key))
	player.play()
	await player.finished

func play_sfx_at_position(key: String, position: Vector3, max_distance: float = 0.0, force: bool = false, pitch_scale: float = 1.0) -> void:
	if not audio_properties.has(key):
		print("Warning: No audio for key ", key)
		return
	
	var props = audio_properties[key]
	if not props.stream:
		print("Warning: No audio stream for ", key)
		return
	
	var player = _get_sfx_3d_player(key, force)
	if not player:
		return
	
	player.stream = props.stream
	player.position = position
	player.volume_db = linear_to_db(props.volume)
	player.pitch_scale = pitch_scale
	
	if max_distance > 0.0:
		player.max_distance = max_distance
	else:
		player.attenuation_filter_cutoff_hz = 20500
		player.max_distance = 0.0
		player.unit_size = 10
	
	player.finished.connect(_on_sfx_3d_finished.bind(player, key))
	player.play()
	await player.finished

func pause_all_sfx() -> void:
	for player in active_sfx_players:
		if player and player.playing:
			player.stream_paused = true

func pause_all_sfx_3d() -> void:
	for player in active_sfx_3d_players:
		if player and player.playing:
			player.stream_paused = true

func resume_all_sfx() -> void:
	for player in active_sfx_players:
		if player and player.stream_paused:
			player.stream_paused = false

func resume_all_sfx_3d() -> void:
	for player in active_sfx_3d_players:
		if player and player.stream_paused:
			player.stream_paused = false

func stop_all_sfx() -> void:
	for player in active_sfx_players:
		if player:
			player.stop()
	_cleanup_sfx_players()

func stop_all_sfx_3d() -> void:
	for player in active_sfx_3d_players:
		if player:
			player.stop()
	_cleanup_sfx_3d_players()

func _on_sfx_finished(player: AudioStreamPlayer, key: String) -> void:
	player.finished.disconnect(_on_sfx_finished)
	_return_sfx_player(player, key)

func _on_sfx_3d_finished(player: AudioStreamPlayer3D, key: String) -> void:
	player.finished.disconnect(_on_sfx_3d_finished)
	_return_sfx_3d_player(player, key)

func _cleanup_sfx_players() -> void:
	# Return all active players to pool
	var players_to_return = active_sfx_players.duplicate()
	for player in players_to_return:
		# Find the key for this player (iterate through counts to find it)
		for key in sfx_per_key_count.keys():
			_return_sfx_player(player, key)
			break

func _cleanup_sfx_3d_players() -> void:
	# Return all active players to pool
	var players_to_return = active_sfx_3d_players.duplicate()
	for player in players_to_return:
		# Find the key for this player (iterate through counts to find it)
		for key in sfx_3d_per_key_count.keys():
			_return_sfx_3d_player(player, key)
			break

# Looping Sound Effects Management

func play_looping_sfx(key: String, loop_id: String, force: bool = false, pitch_scale: float = 1.0) -> void:
	"""Play a looping SFX that can be controlled independently
	loop_id: Unique identifier for this looping sound instance
	force: If true, allows exceeding the 40-player limit
	pitch_scale: Pitch multiplier for the sound (1.0 = normal, 0.5 = half, 2.0 = double)
	"""
	if not audio_properties.has(key):
		print("Warning: No audio for key ", key)
		return
	
	var props = audio_properties[key]
	if not props.stream:
		print("Warning: No audio stream for ", key)
		return
	
	# Stop any existing looping SFX with the same ID
	if loop_id in looping_sfx_players:
		stop_looping_sfx(loop_id)
	
	var player = _get_sfx_player(key, force)
	if not player:
		return
	
	player.stream = props.stream
	player.volume_db = linear_to_db(props.volume)
	player.pitch_scale = pitch_scale
	player.stream_paused = false
	player.play()
	looping_sfx_players[loop_id] = player
	looping_sfx_keys[loop_id] = key

func stop_looping_sfx(loop_id: String) -> void:
	"""Stop a looping SFX by its ID"""
	if loop_id not in looping_sfx_players:
		return
	
	var player = looping_sfx_players[loop_id]
	var key = looping_sfx_keys.get(loop_id, "unknown")
	if player:
		_return_sfx_player(player, key)
	looping_sfx_players.erase(loop_id)
	looping_sfx_keys.erase(loop_id)

func pause_looping_sfx(loop_id: String) -> void:
	"""Pause a looping SFX by its ID"""
	if loop_id not in looping_sfx_players:
		return
	
	var player = looping_sfx_players[loop_id]
	if player and player.playing:
		player.stream_paused = true

func resume_looping_sfx(loop_id: String) -> void:
	"""Resume a paused looping SFX by its ID"""
	if loop_id not in looping_sfx_players:
		return
	
	var player = looping_sfx_players[loop_id]
	if player and player.stream_paused:
		player.stream_paused = false

func is_looping_sfx_playing(loop_id: String) -> bool:
	"""Check if a looping SFX is currently playing"""
	if loop_id not in looping_sfx_players:
		return false
	
	var player = looping_sfx_players[loop_id]
	return player and player.playing and not player.stream_paused

func play_looping_sfx_at_position(key: String, loop_id: String, position: Vector3, max_distance: float = 0.0, force: bool = false, pitch_scale: float = 1.0) -> void:
	"""Play a 3D looping SFX that can be controlled independently
	loop_id: Unique identifier for this looping sound instance
	force: If true, allows exceeding the 40-player limit
	pitch_scale: Pitch multiplier for the sound (1.0 = normal, 0.5 = half, 2.0 = double)
	"""
	if not audio_properties.has(key):
		print("Warning: No audio for key ", key)
		return
	
	var props = audio_properties[key]
	if not props.stream:
		print("Warning: No audio stream for ", key)
		return
	
	# Stop any existing 3D looping SFX with the same ID
	if loop_id in looping_sfx_3d_players:
		stop_looping_sfx_at_position(loop_id)
	
	var player = _get_sfx_3d_player(key, force)
	if not player:
		return
	
	player.stream = props.stream
	player.position = position
	player.volume_db = linear_to_db(props.volume)
	player.pitch_scale = pitch_scale
	player.stream_paused = false
	
	if max_distance > 0.0:
		player.max_distance = max_distance
	else:
		player.attenuation_filter_cutoff_hz = 20500
		player.max_distance = 0.0
		player.unit_size = 10
	
	player.play()
	looping_sfx_3d_players[loop_id] = player
	looping_sfx_3d_keys[loop_id] = key

func stop_looping_sfx_at_position(loop_id: String) -> void:
	"""Stop a 3D looping SFX by its ID"""
	if loop_id not in looping_sfx_3d_players:
		return
	
	var player = looping_sfx_3d_players[loop_id]
	var key = looping_sfx_3d_keys.get(loop_id, "unknown")
	if player:
		_return_sfx_3d_player(player, key)
	looping_sfx_3d_players.erase(loop_id)
	looping_sfx_3d_keys.erase(loop_id)

func pause_looping_sfx_at_position(loop_id: String) -> void:
	"""Pause a 3D looping SFX by its ID"""
	if loop_id not in looping_sfx_3d_players:
		return
	
	var player = looping_sfx_3d_players[loop_id]
	if player and player.playing:
		player.stream_paused = true

func resume_looping_sfx_at_position(loop_id: String) -> void:
	"""Resume a paused 3D looping SFX by its ID"""
	if loop_id not in looping_sfx_3d_players:
		return
	
	var player = looping_sfx_3d_players[loop_id]
	if player and player.stream_paused:
		player.stream_paused = false

func is_looping_sfx_at_position_playing(loop_id: String) -> bool:
	"""Check if a 3D looping SFX is currently playing"""
	if loop_id not in looping_sfx_3d_players:
		return false
	
	var player = looping_sfx_3d_players[loop_id]
	return player and player.playing and not player.stream_paused

func pause_all_looping_sfx() -> void:
	"""Pause all active looping SFX"""
	for player in looping_sfx_players.values():
		if player and player.playing:
			player.stream_paused = true

func pause_all_looping_sfx_at_position() -> void:
	"""Pause all active 3D looping SFX"""
	for player in looping_sfx_3d_players.values():
		if player and player.playing:
			player.stream_paused = true

func resume_all_looping_sfx() -> void:
	"""Resume all paused looping SFX"""
	for player in looping_sfx_players.values():
		if player and player.stream_paused:
			player.stream_paused = false

func resume_all_looping_sfx_at_position() -> void:
	"""Resume all paused 3D looping SFX"""
	for player in looping_sfx_3d_players.values():
		if player and player.stream_paused:
			player.stream_paused = false

func stop_all_looping_sfx() -> void:
	"""Stop all active looping SFX"""
	var loop_ids_to_stop = looping_sfx_players.keys().duplicate()
	for loop_id in loop_ids_to_stop:
		stop_looping_sfx(loop_id)

func stop_all_looping_sfx_at_position() -> void:
	"""Stop all active 3D looping SFX"""
	var loop_ids_to_stop = looping_sfx_3d_players.keys().duplicate()
	for loop_id in loop_ids_to_stop:
		stop_looping_sfx_at_position(loop_id)

# Helper Functions

func play_main_music() -> void:
	await play_music("upbeat_music")

func play_credit_music() -> void:
	await play_music("credits", true)

func play_click_sfx(pitch_scale: float = 1.0) -> void:
	await play_sfx("click", false, pitch_scale)

func play_hover_sfx(pitch_scale: float = 1.0) -> void:
	await play_sfx("hover", false, pitch_scale)

func play_click_sfx_at_pos(pos: Vector3, pitch_scale: float = 1.0) -> void:
	await play_sfx_at_position("click", pos, 0.0, false, pitch_scale)

func play_hover_sfx_at_pos(pos: Vector3, pitch_scale: float = 1.0) -> void:
	await play_sfx_at_position("hover", pos, 0.0, false, pitch_scale)

func play_explosion_sfx(pitch_scale: float = 1.0) -> void:
	await play_sfx("explosion", false, pitch_scale)

func play_shoot_sfx() -> void:
	# random pitch
	var pitch_scale = randf_range(0.9, 1.1)
	await play_sfx("shoot", false, pitch_scale)

func start_jetfart_sfx(loop_id: String, pitch_scale: float = 1.0) -> void:
	print("Starting jetfart sfx with loop_id: " + loop_id)
	await play_looping_sfx("jetfart", loop_id, false, pitch_scale)

func stop_jetfart_sfx(loop_id: String) -> void:
	stop_looping_sfx(loop_id)

func play_bling_sfx(pitch_scale: float = 1.0) -> void:
	# play random bling sound from bling_1 to bling_4
	var bling_index = randi() % 4 + 1
	await play_sfx("bling%d" % bling_index, false, pitch_scale)

func play_dirt_sfx(pitch_scale: float = 1.0) -> void:
	# play random dirt sound from dirt_1 to dirt_5
	var dirt_index = randi() % 5 + 1
	await play_sfx("dirt%d" % dirt_index, false, pitch_scale)

func play_rock_sfx(pitch_scale: float = 1.0) -> void:
	# play random rock sound from rock_1 to rock_6
	var rock_index = randi() % 6 + 1
	await play_sfx("rock%d" % rock_index, false, pitch_scale)
