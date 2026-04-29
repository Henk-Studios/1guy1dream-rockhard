## Manages all audio playback including music, sound effects, and volume control
extends Node
class_name AudioManager

@export var audio_properties: Dictionary[String, AudioProperties]

# Music player reference
var music_player: AudioStreamPlayer

# Music fade settings
const MUSIC_FADE_DURATION: float = 2.0
var music_fade_tween: Tween

# Sound effect players pool
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_3d_players: Array[AudioStreamPlayer3D] = []

# Audio bus indices
var master_bus_index: int
var music_bus_index: int
var sfx_bus_index: int

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

func play_sfx(key: String) -> void:
	if not audio_properties.has(key):
		print("Warning: No audio for key ", key)
		return
	
	var props = audio_properties[key]
	if not props.stream:
		print("Warning: No audio stream for ", key)
		return
	
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = props.stream
	player.volume_db = linear_to_db(props.volume)
	player.bus = "SFX"
	add_child(player)
	player.finished.connect(_on_sfx_finished.bind(player))
	player.play()
	sfx_players.append(player)

func play_sfx_at_position(key: String, position: Vector3, max_distance: float = 0.0) -> void:
	if not audio_properties.has(key):
		print("Warning: No audio for key ", key)
		return
	
	var props = audio_properties[key]
	if not props.stream:
		print("Warning: No audio stream for ", key)
		return
	
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = props.stream
	player.bus = "SFX"
	player.position = position
	player.volume_db = linear_to_db(props.volume)
	
	if max_distance > 0.0:
		player.max_distance = max_distance
	else:
		player.attenuation_filter_cutoff_hz = 20500
		player.max_distance = 0.0
		player.unit_size = 10
	
	add_child(player)
	player.finished.connect(_on_sfx_3d_finished.bind(player))
	player.play()
	
	sfx_3d_players.append(player)

func pause_all_sfx() -> void:
	for player in sfx_players:
		if player and player.playing:
			player.stream_paused = true

func pause_all_sfx_3d() -> void:
	for player in sfx_3d_players:
		if player and player.playing:
			player.stream_paused = true

func resume_all_sfx() -> void:
	for player in sfx_players:
		if player and player.stream_paused:
			player.stream_paused = false

func resume_all_sfx_3d() -> void:
	for player in sfx_3d_players:
		if player and player.stream_paused:
			player.stream_paused = false

func stop_all_sfx() -> void:
	for player in sfx_players:
		if player:
			player.stop()
	_cleanup_sfx_players()

func stop_all_sfx_3d() -> void:
	for player in sfx_3d_players:
		if player:
			player.stop()
	_cleanup_sfx_3d_players()

func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	if player in sfx_players:
		sfx_players.erase(player)
	player.queue_free()

func _on_sfx_3d_finished(player: AudioStreamPlayer3D) -> void:
	if player in sfx_3d_players:
		sfx_3d_players.erase(player)
	player.queue_free()

func _cleanup_sfx_players() -> void:
	sfx_players.clear()

func _cleanup_sfx_3d_players() -> void:
	sfx_3d_players.clear()

# Helper Functions

func play_main_music() -> void:
	play_music("upbeat_music")

func play_click_sfx() -> void:
	play_sfx("click")

func play_hover_sfx() -> void:
	play_sfx("hover")

func play_click_sfx_at_pos(pos: Vector3) -> void:
	play_sfx_at_position("click", pos)

func play_hover_sfx_at_pos(pos: Vector3) -> void:
	play_sfx_at_position("hover", pos)