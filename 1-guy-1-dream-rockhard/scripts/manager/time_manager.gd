## Manages custom timers for game timing and delays
class_name TimeManager
extends Node

var _clocks: Dictionary[int, Timer]
var _max_id: int
var speed: float = 1.0

func _ready():
	self._clocks = {}
	self._max_id = 0

func _exit_tree():
	for timer in self._clocks.values():
		timer.stop()
		timer.queue_free()
	self._clocks.clear()

func new_repeating_timer(delay: float) -> int:
	var new_timer := Timer.new()
	self._clocks[ self._max_id] = new_timer
	self._max_id += 1
		
	new_timer.wait_time = delay
	new_timer.one_shot = false
	
	add_child(new_timer)
	return _max_id - 1

func wait_seconds(delay: float) -> Timer:
	var new_timer := Timer.new()
	new_timer.wait_time = delay
	new_timer.one_shot = true
	add_child(new_timer)
	new_timer.start()
	_delete_one_shot(new_timer)
	return new_timer

func wait_frames(frame_count: int) -> Timer:
	var new_timer := Timer.new()
	new_timer.wait_time = frame_count / Engine.get_frames_per_second()
	new_timer.one_shot = true
	add_child(new_timer)
	new_timer.start()
	_delete_one_shot(new_timer)
	return new_timer
	
func _delete_one_shot(timer: Timer) -> void:
	await timer.timeout
	timer.queue_free()

func get_timer(id: int) -> Timer:
	return self._clocks.get(id)

func delete_timer(id: int) -> void:
	if self._clocks.has(id):
		var timer = self._clocks[id]
		timer.stop()
		timer.queue_free()
		self._clocks.erase(id)
