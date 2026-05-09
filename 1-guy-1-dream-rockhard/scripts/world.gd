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
var dev_mode := false
var debugging := true
var world_name: String = ""
var world_id: String = ""
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

func setup(params) -> void:
	if debugging:
		dev_mode = true
	time_frozen = true

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
		if d.has("player_pos") and the_guy:
			var pp = d["player_pos"]
			if pp and pp.size() >= 2:
				the_guy.global_position = Vector2(pp[0], pp[1])

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
	Manager.scene.finish_loading()
	Manager.message.info(" Use [color=lime]A[/color], [color=lime]D[/color], or [color=lime]<-, ->[/color], (keyboard) or [color=lime]RT[/color], [color=lime]LT[/color] (gamepad) to [color=yellow]move", 20)
	Manager.message.info(" Use [color=lime]Mouse[/color] or [color=lime]Right Stick [/color] (gamepad) to [color=magenta]aim and shoot", 20)
	Manager.message.info(" Press [color=lime]S[/color] (keyboard) or [color=lime]Y + Left Stick[/color] (gamepad) to open the [color=cyan]upgrade menu", 20)
	Manager.message.info(" Press [color=lime]ESC[/color] (keyboard) or [color=lime]Start[/color] (gamepad) to [color=orange]pause", 20)
	Manager.message.info(" [color=magenta][wave amp=10.0]Now be the 1guy and achieve your 1dream!!![/wave][/color]", 20)
	Manager.audio.fade_out_music()

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
	# Seed
	world_data["seed"] = terrain.world_seed if terrain else null
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
