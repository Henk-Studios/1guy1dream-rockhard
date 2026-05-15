extends Polygon2D
class_name Lava

var rising_lava: bool = false
var rise_speed: float = 8.0
var _lava_touch_triggered: bool = false
var previously_above_lava: bool = true

func _process(delta: float) -> void:
	# follow the guy's x position
	position.x = World.camera.position.x
	if rising_lava and not World.main.time_frozen:
		position.y -= rise_speed * delta * (1 + World.main.time_elapsed * 0.01)
		_rise_if_far_below()
	_check_player_touch()

func _check_player_touch() -> void:
	var lava_surface_y := global_position.y - 10.0
	if World.the_guy.global_position.y >= lava_surface_y:
		if previously_above_lava:
			Manager.audio.play_flame_sfx()
		previously_above_lava = false
		if rising_lava and not _lava_touch_triggered:
			_lava_touch_triggered = true
			World.main.time_frozen = true
			var seed_type = World.main.seed_type_used
			var current_record = Manager.utility.get_personal_record(Manager.utility.GameType.INFINITE_RISING_LAVA, seed_type)
			if World.main.time_elapsed > current_record:
				Manager.utility.set_personal_record(World.main.time_elapsed, Manager.utility.GameType.INFINITE_RISING_LAVA, seed_type)
				Manager.message.info("[pulse color=red freq=4.0]You touched the lava![/pulse] It tickles! Your time is [color=cyan]%s[/color] [color=deep_pink][wave](New Record!)[/wave][/color]" % Manager.utility.format_time(World.main.time_elapsed), 30.0)
			else:
				Manager.message.info("[pulse color=red freq=4.0]You touched the lava![/pulse] It tickles! Your time is [color=cyan]%s[/color] (PR: %s)" % [Manager.utility.format_time(World.main.time_elapsed), Manager.utility.format_time(current_record)], 30.0)
		# push the guy up using force
		var upward_force = Vector2(0, -2000)
		print("Lava touched! Applying upward force to the guy.")
		World.the_guy.apply_force(upward_force)
		World.the_guy.fire_particles.emitting = true
		
	else:
		World.the_guy.fire_particles.emitting = false
		previously_above_lava = true

func _rise_if_far_below() -> void:
	var guy_y = World.the_guy.global_position.y
	if guy_y < global_position.y - 300:
		position.y = guy_y + 300

func set_rising_lava(enabled: bool) -> void:
	rising_lava = enabled
	_lava_touch_triggered = false
