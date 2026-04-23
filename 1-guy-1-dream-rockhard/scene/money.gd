extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_label(global.money)

func set_label(money):
	self.text = "$ " + str(money)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	set_label(global.money)
