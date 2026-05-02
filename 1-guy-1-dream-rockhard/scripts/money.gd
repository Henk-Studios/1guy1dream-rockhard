extends RichTextLabel

func _ready() -> void:
	set_label(Global.money)
	Global.money_changed.connect(set_label)

func set_label(money):
	pulse()
	self.text = "$ " + str(money)

func pulse() -> void:
	var tween = create_tween()
	tween.tween_property(self , "scale", Vector2(1.1, 1.1), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self , "scale", Vector2(1, 1), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
