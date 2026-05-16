## Main autoload singleton providing global access to all game managers
extends Node

var dev_mode: bool = false
var follow_mouse: bool = false
var auto_shoot: bool = false

# Main autoload singleton for global access to managers

# Manager references
@onready var audio: AudioManager
@onready var utility: UtilityManager
@onready var scene: SceneManager
@onready var message: MessageManager
@onready var time: TimeManager

func _ready():
	setup_managers()
	await get_tree().process_frame
	if scene:
		scene.load_initial_scene()
	else:
		push_error("SceneManager not found. Initial scene will not be loaded.")

func setup_managers():
	audio = get_node("/root/Main/AudioManager")
	utility = get_node("/root/Main/UtilityManager")
	scene = get_node("/root/Main/SceneManager")
	message = get_node("/root/Main/MessageManager")
	time = get_node("/root/Main/TimeManager")
