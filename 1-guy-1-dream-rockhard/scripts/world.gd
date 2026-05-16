extends Node2D
class_name LocalWorld

@export var terrain: Terrain
@export var the_guy: TheGuy
@export var camera: Camera2D
@export var credits: Credits
@export var lava: Lava
@export var bullet_pool: BulletPool
@export var break_particle_pool: ParticlePool
@export var explode_particle_pool: ParticlePool
var time_frozen: bool = true
var time_elapsed: float = 0.0


var shop_open := false
var jetpackspeed = 700
signal money_changed(money)
# enable dev mode by clicking the top right corner 3 times in the main menu (??? message will appear when toggled)
var world_name: String = ""
var world_id: String = ""
var gamemode: int = 0
var rising_lava_enabled: bool = false
var seed_type_used: int = 0
var money: int:
	set(value):
		money = value
		money_changed.emit(money)
var damage = 100
var piercing = 0
var ricochet = 0
var width := 0.1 # cone half-angle (radians)
var particles_per_second := 5
var particle_speed := 300.0
var vision := 0.3

# Explosive-bullet upgrades. 0 = no explosions.
var bullet_explosive_chance_level: int = 0 # likelihood — 1% per level
var bullet_explosive_size_level: int = 0 # blast radius bonus

func _physics_process(delta: float) -> void:
	if not time_frozen:
		time_elapsed += delta
		if gamemode == Manager.utility.GameType.RACE_TO_SPACE and time_elapsed >= Manager.utility.GAME_TYPE_DEFINITIONS[Manager.utility.GameType.RACE_TO_SPACE]["duration"]:
			time_frozen = true
			var score: float = the_guy.global_position.y * -1
			var current_record: float = Manager.utility.get_personal_record(Manager.utility.GameType.RACE_TO_SPACE, seed_type_used)
			var new_pr: bool = score > current_record
			if new_pr:
				Manager.message.info("Time's up! You reached a height of %d!  [color=deep_pink][wave](New Record!)[/wave][/color]" % score)
				Manager.utility.set_personal_record(score, Manager.utility.GameType.RACE_TO_SPACE, seed_type_used)
			else:
				Manager.message.info("Time's up! You reached a height of %d!" % score)
		elif gamemode == Manager.utility.GameType.RACE_TO_RICHES and time_elapsed >= Manager.utility.GAME_TYPE_DEFINITIONS[Manager.utility.GameType.RACE_TO_RICHES]["duration"]:
			time_frozen = true
			var score: int = money
			var current_record: int = int(Manager.utility.get_personal_record(Manager.utility.GameType.RACE_TO_RICHES, seed_type_used))
			var new_pr: bool = score > current_record
			if new_pr:
				Manager.message.info("Time's up! You collected $%d!  [color=deep_pink][wave](New Record!)[/wave][/color]" % money)
				Manager.utility.set_personal_record(World.main.money, Manager.utility.GameType.RACE_TO_RICHES, seed_type_used)
			else:
				Manager.message.info("Time's up! You collected $%d!" % money)

func setup(params) -> void:
	time_frozen = true

	# If load data exists, restore gamemode and rising_lava from saved data before terrain setup
	if params and params.has("load_data") and params["load_data"] != null:
		var d: Dictionary = params["load_data"]
		if d.has("gamemode") and d["gamemode"] != null:
			params["gamemode"] = d["gamemode"]

	# Extract gamemode and rising_lava from params or defaults
	gamemode = params.get("gamemode", 0) if params else 0
	print("Setting up world with gamemode: %s" % gamemode)
	rising_lava_enabled = params.get("rising_lava", false) if params else false
	
	# Determine seed type (set vs random)
	if params and params.has("seed") and params["seed"] != null and str(params["seed"]) != "":
		seed_type_used = Manager.utility.SeedType.SET
	else:
		seed_type_used = Manager.utility.SeedType.RANDOM

	World.setup(self , terrain, the_guy, camera, credits, lava, break_particle_pool, explode_particle_pool, bullet_pool)

	# If load data contains saved broken blocks, restore them before terrain generation
	if params and params.has("load_data") and params["load_data"] != null and params["load_data"].has("broken_by_group") and terrain:
		var saved = params["load_data"]["broken_by_group"]
		var restored := {}
		for gstr in saved.keys():
			var gparts = str(gstr).split(",")
			if gparts.size() < 2:
				continue
			var gx = int(gparts[0])
			var gy = int(gparts[1])
			var gvec = Vector2i(gx, gy)
			var inner_saved = saved[gstr]
			var inner_rest := {}
			for cstr in inner_saved.keys():
				var cparts = str(cstr).split(",")
				if cparts.size() < 2:
					continue
				var cx = int(cparts[0])
				var cy = int(cparts[1])
				inner_rest[Vector2i(cx, cy)] = int(inner_saved[cstr])
			restored[gvec] = inner_rest
		terrain.broken_by_group = restored

	terrain.setup(params)

	# If a saved world was passed in params, restore basic state now
	if params and params.has("name") and params["name"] != null:
		world_name = params["name"]
	if params and params.has("load_data") and params["load_data"] != null:
		var d: Dictionary = params["load_data"]
		world_id = Manager.utility.resolve_world_id(str(params.get("save_path", "")), d)
		if d.has("name") and d["name"] != null:
			world_name = d["name"]
		if d.has("money"):
			money = int(d["money"]) if d["money"] != null else money
		if d.has("time_elapsed"):
			time_elapsed = float(d["time_elapsed"]) if d["time_elapsed"] != null else time_elapsed
		if d.has("gamemode") and d["gamemode"] != null:
			gamemode = int(d["gamemode"])
		if d.has("seed_type") and d["seed_type"] != null:
			seed_type_used = int(d["seed_type"])
		if d.has("player_pos") and the_guy:
			var pp = d["player_pos"]
			if pp and pp.size() >= 2:
				the_guy.global_position = Vector2(pp[0], pp[1])

		# Restore lava height if rising lava is enabled
		if rising_lava_enabled and lava and d.has("lava_height") and d["lava_height"] != null:
			lava.position.y = float(d["lava_height"])

		# Restore broken blocks into terrain.broken_by_group (Vector2i keys)
		if d.has("broken_by_group") and terrain:
			var saved = d["broken_by_group"]
			var restored := {}
			for gstr in saved.keys():
				var gparts = str(gstr).split(",")
				if gparts.size() < 2:
					continue
				var gx = int(gparts[0])
				var gy = int(gparts[1])
				var gvec = Vector2i(gx, gy)
				var inner_saved = saved[gstr]
				var inner_rest := {}
				for cstr in inner_saved.keys():
					var cparts = str(cstr).split(",")
					if cparts.size() < 2:
						continue
					var cx = int(cparts[0])
					var cy = int(cparts[1])
					inner_rest[Vector2i(cx, cy)] = int(inner_saved[cstr])
				restored[gvec] = inner_rest
			terrain.broken_by_group = restored
	if world_id == "" and params and params.has("save_path"):
		world_id = Manager.utility.resolve_world_id(str(params.get("save_path", "")), {})
	camera.setup()
	var shop = get_node("WorldUI/CenterControl/RadialMenu") as RadialMenu
	shop.setup()
	# Apply saved upgrades if present in load params
	if params and params.has("load_data") and params["load_data"] != null:
		var ld: Dictionary = params["load_data"]
		if ld.has("upgrade_levels") or ld.has("upgrade_prices"):
			var levels = ld.get("upgrade_levels", [])
			var prices = ld.get("upgrade_prices", [])
			shop.apply_upgrade_state(levels, prices)
	Manager.scene.finish_loading()
	if str(params.get("seed", "")) != "":
		Manager.message.info("Loaded world with seed: '%s'" % (params.get("seed", "Unknown")), 20)
	Manager.message.info(" Use [color=lime]A[/color], [color=lime]D[/color], or [color=lime]<-, ->[/color], (keyboard) or [color=lime]RT[/color], [color=lime]LT[/color] (gamepad) to [color=yellow]move", 20)
	Manager.message.info(" Use [color=lime]Mouse[/color] or [color=lime]Right Stick [/color] (gamepad) to [color=magenta]aim and shoot", 20)
	Manager.message.info(" Press [color=lime]S[/color] (keyboard) or [color=lime]Y + Left Stick[/color] (gamepad) to open the [color=cyan]upgrade menu", 20)
	Manager.message.info(" Press [color=lime]ESC[/color] (keyboard) or [color=lime]Start[/color] (gamepad) to [color=orange]pause", 20)
	# per-gamemode instructions
	match gamemode:
		Manager.utility.GameType.CLASSIC, Manager.utility.GameType.INFINITE:
			Manager.message.info("[color=yellow]Your 1dream: Reach the surface as fast as possible!", 20)
		Manager.utility.GameType.INFINITE_RISING_LAVA:
			Manager.message.info("[color=yellow]Your 1dream: Avoid the lava as long as possible!")
		Manager.utility.GameType.RACE_TO_SPACE:
			Manager.message.info("[color=yellow]Your 1dream: Go as high as possible in 5 minutes!")
		Manager.utility.GameType.RACE_TO_RICHES:
			Manager.message.info("[color=yellow]Your 1dream: Get as rich as possible in 10 minutes!")
	Manager.message.info(" [color=magenta][wave amp=10.0]Now be the 1guy and achieve your 1dream!!![/wave][/color]", 20)
	Manager.audio.fade_out_music()
	# freeze the guy if loading a saved world
	if params and params.has("load_data") and params["load_data"] != null:
		the_guy.freeze_guy()
	await get_node("WorldUI/Countdown").countdown()
	the_guy.enable()
	time_frozen = false
	Manager.audio.play_main_music()

func save_state() -> void:
	if world_id == "":
		world_id = Manager.utility.generate_world_id()
	Manager.utility.ensure_save_dir()
	var save_path = Manager.utility.world_id_to_save_path(world_id)
	var config := ConfigFile.new()
	var world_data: Dictionary = {}
	# Game version
	world_data["version"] = Manager.utility.GAME_VERSION
	# Seed
	world_data["seed"] = terrain.world_seed
	world_data["world_id"] = world_id

	# World name
	world_data["name"] = world_name

	# Player position
	if the_guy:
		world_data["player_pos"] = [the_guy.global_position.x, the_guy.global_position.y]

	# Basic world state
	world_data["money"] = money
	world_data["time_elapsed"] = time_elapsed
	world_data["last_played"] = Time.get_datetime_string_from_system(true, true)
	world_data["save_timestamp"] = int(Time.get_unix_time_from_system())
	
	# Gamemode
	world_data["gamemode"] = gamemode
	world_data["seed_type"] = seed_type_used
	
	# Lava height (only save if rising lava is enabled)
	if rising_lava_enabled and lava:
		world_data["lava_height"] = lava.position.y

	# Save shop upgrade levels and next-upgrade prices
	var shop_node = get_node_or_null("WorldUI/CenterControl/RadialMenu")
	if shop_node:
		var up_levels := []
		var up_prices := []
		for b in shop_node.button_instances:
			up_levels.append(int(b.level))
			up_prices.append(int(b.price))
		world_data["upgrade_levels"] = up_levels
		world_data["upgrade_prices"] = up_prices

	# Broken blocks: serialize as nested string-keyed dictionaries
	var broken_serial := {}
	if terrain and typeof(terrain.broken_by_group) == TYPE_DICTIONARY:
		for group_key in terrain.broken_by_group.keys():
			var group = terrain.broken_by_group[group_key]
			var gstr := ""
			if typeof(group_key) == TYPE_VECTOR2 or typeof(group_key) == TYPE_VECTOR2I:
				gstr = "%d,%d" % [int(group_key.x), int(group_key.y)]
			else:
				gstr = str(group_key)
			var inner := {}
			for cell_key in group.keys():
				var cstr := ""
				if typeof(cell_key) == TYPE_VECTOR2 or typeof(cell_key) == TYPE_VECTOR2I:
					cstr = "%d,%d" % [int(cell_key.x), int(cell_key.y)]
				else:
					cstr = str(cell_key)
				inner[cstr] = int(group[cell_key])
			broken_serial[gstr] = inner

	world_data["broken_by_group"] = broken_serial

	config.set_value("world", "data", world_data)
	var err := config.save(save_path)
	if err != OK:
		push_error("Failed to save world state: %s" % save_path)
	else:
		Manager.message.info("World saved (%s)" % world_id)
