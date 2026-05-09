extends RichTextLabel
class_name Countdown

signal countdown_finished

func _ready() -> void:
	visible = false
	modulate.a = 0.0

func countdown() -> void:
	"""Count down from 3 to GO with a pulse effect. Can be awaited."""
	visible = true
	
	_richtext_countdown()
	await get_tree().create_timer(4.0).timeout
	countdown_finished.emit()

func _richtext_countdown() -> void:
	# Numbers to display
	var numbers: Array[String] = ["[font size=100][color=yellow] 3 ", "[font size=100][color=cyan] 2 ", "[font size=100][color=magenta] 1 ", "[font size=100][color=lime][shake] GO! "]
	await get_tree().create_timer(1.0).timeout
	for num in numbers:
		text = num
		modulate.a = 1.0
		scale = Vector2.ONE
		rotation_degrees = randf_range(-20, 20)
		
		# Pulse animation using tween
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		
		# Scale pulse effect
		tween.tween_property(self , "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(self , "scale", Vector2.ONE, 0.3).set_delay(0.7 if num != numbers[-1] else 1.5)

		# Fade out towards the end
		tween.tween_property(self , "modulate:a", 0.0, 0.3).set_delay(0.7 if num != numbers[-1] else 1.5)
		
		if num != numbers[-1]:
			Manager.audio.play_321_sfx()
		else:
			Manager.audio.play_go_sfx()
		
		await get_tree().create_timer(1.0 if num != numbers[-1] else 2.0).timeout
		tween.kill()
	visible = false
