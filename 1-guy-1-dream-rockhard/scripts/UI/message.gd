## Individual message display component with styling based on message type
extends Control
class_name Message

enum MessageType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
	DEBUG
}

@export var message_label: RichTextLabel

const MAX_CHARS_PER_LINE = 27
const LINE_HEIGHT = 16
const SINGLE_LINE_HEIGHT = 40
const PADDING_VERTICAL = 20

func setup(text: String, type: MessageType) -> void:
	self.message_label.text = text
	_apply_style(type)

func _apply_style(type: MessageType) -> void:
	var color = _get_color(type)
	self.message_label.add_theme_color_override("default_color", color)

func _get_color(type: MessageType) -> Color:
	match type:
		MessageType.INFO:
			return Color.WHITE
		MessageType.SUCCESS:
			return Color.GREEN
		MessageType.WARNING:
			return Color.YELLOW
		MessageType.ERROR:
			return Color.RED
		MessageType.DEBUG:
			return Color.ORANGE
		_:
			return Color.WHITE
