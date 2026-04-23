extends ColorRect
@onready var credit_screen = $RichTextLabel
@onready var credit_audio = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.credits.connect(start_credits)


func start_credits():
	get_tree().paused = true

	# show UI (must ignore pause)
	credit_screen.visible = true
	credit_screen.process_mode = Node.PROCESS_MODE_ALWAYS

	# play audio
	credit_audio.play()

	# wait for audio to finish
	await credit_audio.finished

	# hide UI
	credit_screen.visible = false

	# resume game
	get_tree().paused = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
