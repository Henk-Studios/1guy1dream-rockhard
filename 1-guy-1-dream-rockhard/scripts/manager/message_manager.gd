## Displays in-game messages and notifications with different message types
extends CanvasLayer
class_name MessageManager

@export var message_container: VBoxContainer

const DEBUG = false

enum MessageType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
	DEBUG
}
const MESSAGE_SCENE = preload("res://scenes/message.tscn")
const MAX_MESSAGES = 7
const MESSAGE_DURATION = 5.0
const MESSAGE_SPACING = 10
const MESSAGE_START_Y = 20
var active_messages: Array = []
var message_timers: Dictionary = {}
var message_repeat_counts: Dictionary = {}

func print_message(text: String, type: MessageType = MessageType.INFO, duration: float = MESSAGE_DURATION) -> void:
	if type == MessageType.DEBUG and not DEBUG:
		return
	
	if self.active_messages.size() > 0:
		var last_message = self.active_messages[-1]
		if _is_message_identical(last_message, text):
			_increment_repeat_count(last_message, text)
			_reset_message_timer(last_message, duration)
			return
	if self.active_messages.size() >= self.MAX_MESSAGES:
		_remove_oldest_message()
	
	var message = self.MESSAGE_SCENE.instantiate()
	self.message_container.add_child(message)
	message.setup(text, type)
	self.active_messages.append(message)
	self.message_repeat_counts[message] = 1
	
	_start_removal_timer(message, duration)

# TODO spamming messages causes errors

func _start_removal_timer(message_node: Control, duration: float) -> void:
	var timer = get_tree().create_timer(duration)
	self.message_timers[message_node] = timer
	timer.timeout.connect(_remove_message.bind(message_node))

func _reset_message_timer(message_node: Control, duration: float) -> void:
	_start_removal_timer(message_node, duration)

func _is_message_identical(message_node: Control, text: String) -> bool:
	var displayed_text = message_node.message_label.text
	var base_text = _extract_base_text(displayed_text)
	return base_text == text

func _extract_base_text(text: String) -> String:
	var regex = RegEx.new()
	regex.compile(" \\(\\d+\\)$")
	var result = regex.sub(text, "")
	return result

func _increment_repeat_count(message_node: Control, original_text: String) -> void:
	if self.message_repeat_counts.has(message_node):
		self.message_repeat_counts[message_node] += 1
	else:
		self.message_repeat_counts[message_node] = 2
	
	var count = self.message_repeat_counts[message_node]
	message_node.message_label.text = original_text + " (" + str(count) + ")"

func _remove_message(message_node: Control) -> void:
	if message_node and is_instance_valid(message_node):
		self.active_messages.erase(message_node)
		self.message_repeat_counts.erase(message_node)
		message_node.queue_free()

func _remove_oldest_message() -> void:
	if self.active_messages.size() > 0:
		var oldest = self.active_messages[0]
		_remove_message(oldest)

# Public methods for different message types

func info(text: String, duration: float = MESSAGE_DURATION) -> void:
	print_message(text, MessageType.INFO, duration)

func success(text: String, duration: float = MESSAGE_DURATION) -> void:
	print_message(text, MessageType.SUCCESS, duration)

func warning(text: String, duration: float = MESSAGE_DURATION) -> void:
	print_message(text, MessageType.WARNING, duration)

func error(text: String, duration: float = MESSAGE_DURATION) -> void:
	print_message(text, MessageType.ERROR, duration)

func debug(text: String, duration: float = MESSAGE_DURATION) -> void:
	print_message(text, MessageType.DEBUG, duration)
