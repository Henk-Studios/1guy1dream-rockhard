extends RichTextLabel

func _ready() -> void:
	await get_tree().process_frame # wait a frame to ensure World is initialized
	set_label(World.main.money)
	World.main.money_changed.connect(set_label)

func set_label(money):
	pulse()
	self.text = "$ " + str(money)

func pulse() -> void:
	var tween = create_tween()
	tween.tween_property(self , "scale", Vector2(1.1, 1.1), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self , "scale", Vector2(1, 1), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
