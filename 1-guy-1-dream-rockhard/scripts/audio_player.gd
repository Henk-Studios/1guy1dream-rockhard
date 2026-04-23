extends Node

# Dictionary where keys = names, values = AudioStream resources
@export var sounds: Dictionary[String, AudioStream] = {}

# Separate players for music and SFX
var music_player: AudioStreamPlayer
var sfx_players: Array = []

# How many simultaneous SFX can play
@export var sfx_pool_size: int = 8

func _ready():
    # Create music player
    music_player = AudioStreamPlayer.new()
    add_child(music_player)

    # Create SFX pool
    for i in range(sfx_pool_size):
        var player = AudioStreamPlayer.new()
        add_child(player)
        sfx_players.append(player)

    play_music("music 1")


# --- MUSIC ---

func play_music(name: String, loop: bool = true):
    if not sounds.has(name):
        push_warning("Music not found: %s" % name)
        return

    var stream: AudioStream = sounds[name]
    music_player.stream = stream

    if stream is AudioStream:
        stream.loop = loop

    music_player.play()


func stop_music():
    music_player.stop()


# --- SOUND EFFECTS ---

func play_sfx(name: String):
    if not sounds.has(name):
        push_warning("SFX not found: %s" % name)
        return

    var stream: AudioStream = sounds[name]

    # Find a free player
    for player in sfx_players:
        if not player.playing:
            player.stream = stream
            player.play()
            return

    # If all busy, reuse the first one
    sfx_players[0].stream = stream
    sfx_players[0].play()

func start_looping_sfx(name: String):
    if not sounds.has(name):
        push_warning("SFX not found: %s" % name)
        return

    var stream: AudioStream = sounds[name]

    # Find a free player
    for player in sfx_players:
        if not player.playing:
            player.stream = stream
            player.stream.loop = true
            player.play()
            return

    # If all busy, reuse the first one
    sfx_players[0].stream = stream
    sfx_players[0].stream.loop = true
    sfx_players[0].play()

func stop_looping_sfx(name: String):
    for player in sfx_players:
        if player.playing and player.stream == sounds[name]:
            player.stop()


# --- OPTIONAL HELPERS ---

func stop_all_sfx():
    for player in sfx_players:
        player.stop()


func stop_all():
    stop_music()
    stop_all_sfx()