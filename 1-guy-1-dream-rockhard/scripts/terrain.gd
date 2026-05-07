extends Node2D
class_name Terrain
const TILE_SIZE: int = 16
const CHUNK_SIZE: int = 8
const BREAK_GROUP_CHUNKS: int = 8
const LOAD_RADIUS_X: int = 5
const LOAD_RADIUS_Y: int = 3
const FREE_CAM_RADIUS_MULT: float = 2.0
const EXPLOSION_OVERKILL: int = 999999
var world_thickness: int = 0

class Layer:
	var type: int
	var thickness: int
	var background: Color
	var patches: Array
	func _init(p_type: int = -1, p_thickness: int = 0, p_background: Color = Color(0, 0, 0), p_patches: Array = []):
		self.type = p_type
		self.thickness = p_thickness
		self.background = p_background
		self.patches = p_patches

class Patch:
	var type: int
	var noise_gen: NoiseConfig
	var threshold: float
	var invert: bool = false
	var patches: Array
	func _init(p_type: int = -1, p_noise_gen: NoiseConfig = null, p_threshold: float = 0.0, p_invert: bool = false, p_patches: Array = []):
		self.type = p_type
		self.noise_gen = p_noise_gen
		self.threshold = p_threshold
		self.invert = p_invert
		self.patches = p_patches

class NoiseConfig:
	var style: StringName # High-level noise character: blobby, ridged, billowy, value.
	var size: float # Feature scale from small (0.0) to large (1.0).
	var detail: float # Amount of fine detail layered into the pattern.
	var roughness: float # Contrast/harshness of variation between highs and lows.
	var spaghettiness: float # How stringy and tunnel-like the pattern becomes.
	var rarity: float # Rarity bias used to nudge thresholds toward common or rare.
	var intensity: float # Reserved strength multiplier for future weighting controls.
	var noise = FastNoiseLite.new()
	var variation: int = 0
	func _init(p_style: StringName = &"blobby", p_size: float = 0.5, p_rarity: float = 0.5, p_spaghettiness: float = 0.0, p_detail: float = 0.5, p_roughness: float = 0.4, p_intensity: float = 1.0):
		self.style = p_style
		self.size = p_size
		self.detail = p_detail
		self.roughness = p_roughness
		self.spaghettiness = p_spaghettiness
		self.rarity = p_rarity
		self.intensity = p_intensity


	func duplicate() -> NoiseConfig:
		var copy := NoiseConfig.new()
		copy.style = self.style
		copy.size = self.size
		copy.detail = self.detail
		copy.roughness = self.roughness
		copy.spaghettiness = self.spaghettiness
		copy.rarity = self.rarity
		copy.intensity = self.intensity
		return copy

	# offset seed
	func o_s(vari: int) -> NoiseConfig:
		var copy := self.duplicate()
		copy.variation = vari
		return copy

	# Can only be configured after world_seed is set.
	func configure(p_seed: int) -> void:
		self.noise.noise_type = FastNoiseLite.TYPE_PERLIN
		self.noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		if style == &"ridged":
			self.noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
		elif style == &"billowy":
			self.noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
		elif style == &"value":
			self.noise.noise_type = FastNoiseLite.TYPE_VALUE

		var seed_offset := int(hash(Vector2i(p_seed, self.variation)))

		var size_clamped := clampf(size, 0.0, 1.0)
		var detail_clamped := clampf(detail, 0.0, 1.0)
		var roughness_clamped := clampf(roughness, 0.0, 1.0)
		var spaghetti_clamped := clampf(spaghettiness, 0.0, 1.0)

		var base_frequency: float = lerpf(0.18, 0.005, size_clamped)
		var detail_multiplier: float = lerpf(0.7, 1.8, detail_clamped)
		self.noise.frequency = base_frequency * detail_multiplier
		self.noise.fractal_octaves = clampi(roundi(lerpf(1.0, 6.0, detail_clamped)), 1, 8)
		self.noise.fractal_gain = lerpf(0.25, 0.85, roughness_clamped)
		self.noise.fractal_lacunarity = lerpf(1.6, 2.8, detail_clamped)
		self.noise.fractal_weighted_strength = lerpf(0.0, 1.0, spaghetti_clamped)
		self.noise.fractal_ping_pong_strength = lerpf(1.0, 2.2, spaghetti_clamped)
		self.noise.seed = p_seed ^ seed_offset
		if spaghetti_clamped > 0.75:
			self.noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG

var noises: Dictionary[String, NoiseConfig] = {
	"ridged": NoiseConfig.new(&"ridged", 0.74, 0.50, 0.15, 0.25, 0.35),
	"blobby": NoiseConfig.new(&"blobby", 0.92, 0.50, 0.65, 0.45, 0.45),
	"smooth": NoiseConfig.new(&"blobby", 0.74, 0.50, 0.05, 0.35, 0.40),
	"chunky": NoiseConfig.new(&"blobby", 0.24, 0.70, 0.20, 0.65, 0.50),
	"speckled": NoiseConfig.new(&"blobby", 0.55, 0.78, 0.10, 0.40, 0.45),
	"crystalline": NoiseConfig.new(&"blobby", 0.40, 0.84, 0.20, 0.45, 0.50),
	"dense": NoiseConfig.new(&"blobby", 0.30, 0.90, 0.20, 0.45, 0.55),
	"spaghetti": NoiseConfig.new(&"billowy", 0.90, 0.86, 0.95, 0.55, 0.55),
}

# Recursive patch generator removed; patches are hard-coded below for clarity

var patches: Dictionary = {
	"stone_1": [
		Patch.new(-1, noises["ridged"].o_s(1), 0.8),
		Patch.new(-1, noises["blobby"].o_s(2), -0.65, true),
		Patch.new(Tile.Type.EXPLOSIVE, noises["chunky"].o_s(3), 0.42),
		Patch.new(Tile.Type.EXPLOSIVE, noises["spaghetti"].o_s(4), -0.65, true),
		Patch.new(Tile.Type.GOLD, noises["speckled"].o_s(5), 0.50),
		Patch.new(Tile.Type.DIAMOND, noises["crystalline"].o_s(6), 0.30),
		Patch.new(Tile.Type.EMERALD, noises["spaghetti"].o_s(7), 0.62),
	],

	"stone_2": [
		Patch.new(-1, noises["ridged"].o_s(8), 0.8),
		Patch.new(-1, noises["blobby"].o_s(9), -0.55, true),
		Patch.new(Tile.Type.STONE_1, noises["smooth"].o_s(10), 0.3, false, [
			Patch.new(Tile.Type.EMERALD, noises["smooth"].o_s(10), 0.54)]),
		Patch.new(Tile.Type.EXPLOSIVE, noises["chunky"].o_s(11), 0.45),
		Patch.new(Tile.Type.GOLD, noises["speckled"].o_s(12), 0.40),
		Patch.new(Tile.Type.DIAMOND, noises["crystalline"].o_s(13), 0.35),
		Patch.new(Tile.Type.EMERALD, noises["spaghetti"].o_s(14), 0.9),
	],

	"stone_3": [
		Patch.new(-1, noises["ridged"].o_s(15), 0.8),
		Patch.new(-1, noises["blobby"].o_s(16), -0.45, true),
		Patch.new(Tile.Type.STONE_2, noises["smooth"].o_s(17), 0.3),
		Patch.new(Tile.Type.EXPLOSIVE, noises["chunky"].o_s(18), 0.49),
		Patch.new(Tile.Type.EXPLOSIVE, noises["spaghetti"].o_s(19), -0.45, true),
		Patch.new(Tile.Type.GOLD, noises["speckled"].o_s(20), 0.35),
		Patch.new(Tile.Type.DIAMOND, noises["crystalline"].o_s(21), 0.40),
	],

	"stone_4": [
		Patch.new(-1, noises["ridged"].o_s(22), 0.8),
		Patch.new(-1, noises["blobby"].o_s(23), -0.35, true),
		Patch.new(Tile.Type.STONE_3, noises["smooth"].o_s(24), 0.3, false, [
				Patch.new(Tile.Type.EXPLOSIVE, noises["smooth"].o_s(24), 0.5),
				Patch.new(Tile.Type.DIAMOND, noises["smooth"].o_s(24), 0.45)
			]),
		Patch.new(Tile.Type.EXPLOSIVE, noises["chunky"].o_s(25), 0.52),
		Patch.new(Tile.Type.EXPLOSIVE, noises["spaghetti"].o_s(26), -0.55, true),
		Patch.new(Tile.Type.GOLD, noises["speckled"].o_s(27), 0.30),
		Patch.new(Tile.Type.DIAMOND, noises["crystalline"].o_s(28), 0.45),
	],

	"stone_5": [
		Patch.new(-1, noises["ridged"].o_s(29), 0.8),
		Patch.new(-1, noises["blobby"].o_s(30), -0.25, true),
		Patch.new(Tile.Type.STONE_4, noises["smooth"].o_s(31), 0.3, false, [
				Patch.new(Tile.Type.DIAMOND, noises["smooth"].o_s(31), 0.45)
			]),
		Patch.new(Tile.Type.EXPLOSIVE, noises["chunky"].o_s(32), 0.55),
		Patch.new(Tile.Type.GOLD, noises["speckled"].o_s(33), 0.25),
		Patch.new(Tile.Type.DIAMOND, noises["crystalline"].o_s(34), 0.50),
	],
}

var layers: Dictionary[String, Layer] = {
	"dirt": Layer.new(Tile.Type.DIRT, 50, Color.hex(0x52371d)),
	"stone_1": Layer.new(Tile.Type.STONE_1, 100, Color.hex(0x000000ff), patches["stone_1"]),
	"stone_2": Layer.new(Tile.Type.STONE_2, 100, Color.hex(0x000000ff), patches["stone_2"]),
	"stone_3": Layer.new(Tile.Type.STONE_3, 100, Color.hex(0x000000ff), patches["stone_3"]),
	"stone_4": Layer.new(Tile.Type.STONE_4, 100, Color.hex(0x000000ff), patches["stone_4"]),
	"stone_5": Layer.new(Tile.Type.STONE_5, 100, Color.hex(0x000000ff), patches["stone_5"]),
}

var terrain_config: Dictionary = {
	"surface_base": 15,
	"surface_amplitude": 6,
	"spawn_cell": Vector2i(0, 540),
	"spawn_clear_radius": 5,
	"surface_background_color": Color(0.45, 0.7, 0.9),
	"depths_background_color": Color(0.08, 0.08, 0.10),
	"explosion_base_radius": 2.0,
	"explosion_chain_bonus": 0.3,
	"noises": noises,
	"patches": patches,
	"layers": [
		layers["dirt"],
		layers["stone_1"],
		layers["stone_2"],
		layers["stone_3"],
		layers["stone_4"],
		layers["stone_5"],
	]
}

const STONE_TYPES := [
	Tile.Type.STONE_1,
	Tile.Type.STONE_2,
	Tile.Type.STONE_3,
	Tile.Type.STONE_4,
	Tile.Type.STONE_5,
]


@export var tile_scene: PackedScene

var world_seed: int
var surface_noise: FastNoiseLite
var loaded_chunks: Dictionary = {} # Vector2i chunk -> Dictionary[cell, Tile] (O(1) break removal)
var active_tiles: Dictionary = {} # Vector2i cell -> Tile (fast break lookup)
# Per-cell damage, grouped by break-group coord: group -> Dictionary[cell, hp_lost].
# A cell is fully broken once its hp_lost >= Tile.HP[tile_type]. Partial damage persists
# across chunk unload/reload so a half-mined block stays half-mined.
var broken_by_group: Dictionary = {}

var tile_pool: Array[Tile] = []
var _last_streamed_chunk: Vector2i = Vector2i(-2147483648, -2147483648)

func setup(params: Dictionary) -> void:
	if params.has("seed") and params["seed"] is int:
		world_seed = params["seed"]
	else:
		world_seed = randi()

	surface_noise = FastNoiseLite.new()
	surface_noise.seed = world_seed ^ 0x12345678
	surface_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	surface_noise.frequency = 0.03

	_setup_patches_recursive(terrain_config.layers)


	_clear_spawn_area(terrain_config.spawn_cell, terrain_config.spawn_clear_radius)
	var spawn_world: Vector2 = Vector2(terrain_config.spawn_cell) * TILE_SIZE
	for layer: Layer in terrain_config.layers:
		world_thickness += layer.thickness
	World.the_guy.global_position = spawn_world
	_setup_lava()
	update_region(spawn_world)
	Manager.scene.finish_loading()

func _setup_patches_recursive(items: Array) -> void:
	for item in items:
		var item_patches: Array = []
		if item is Layer:
			item_patches = (item as Layer).patches
		elif item is Patch:
			item_patches = (item as Patch).patches

		for patch in item_patches:
			if patch.noise_gen != null:
				patch.noise_gen.configure(world_seed)
			if not patch.patches.is_empty():
				_setup_patches_recursive([patch])
func _process(_delta: float) -> void:
	var tracking_pos: Vector2
	if World.camera.free_cam_enabled:
		tracking_pos = World.camera.global_position
		# Freecam debug: click or hold left mouse to delete blocks under the cursor.
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break_cell_at_world_pos(get_global_mouse_position(), EXPLOSION_OVERKILL)
	else:
		tracking_pos = World.camera.global_position
	_update_sky(tracking_pos.y)
	var chunk := _world_to_chunk(tracking_pos)
	if chunk != _last_streamed_chunk:
		_last_streamed_chunk = chunk
		update_region(tracking_pos)

func _clear_spawn_area(center: Vector2i, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var cell := center + Vector2i(dx, dy)
				var group := _chunk_to_break_group(_cell_to_chunk(cell))
				var group_broken: Dictionary = broken_by_group.get(group, {})
				group_broken[cell] = EXPLOSION_OVERKILL
				if not broken_by_group.has(group):
					broken_by_group[group] = group_broken

func _setup_lava() -> void:
	World.lava.position.y = (world_thickness) * TILE_SIZE
	print("World thickness:", world_thickness, "Lava Y:", World.lava.position.y)

func update_region(world_pos: Vector2) -> void:
	var rx = LOAD_RADIUS_X
	var ry = LOAD_RADIUS_Y
	if World.camera.free_cam_enabled:
		rx = roundi(LOAD_RADIUS_X * FREE_CAM_RADIUS_MULT)
		ry = roundi(LOAD_RADIUS_Y * FREE_CAM_RADIUS_MULT)
	var center := _world_to_chunk(world_pos)
	var wanted: Dictionary = {}
	for dx in range(-rx, rx + 1):
		for dy in range(-ry, ry + 1):
			var chunk := center + Vector2i(dx, dy)
			wanted[chunk] = true
			if not loaded_chunks.has(chunk):
				_generate_chunk(chunk)
	for chunk in loaded_chunks.keys():
		if not wanted.has(chunk):
			_unload_chunk(chunk)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	var chunk_pixels: float = CHUNK_SIZE * TILE_SIZE
	return Vector2i(floor(world_pos.x / chunk_pixels), floor(world_pos.y / chunk_pixels))

func _generate_chunk(chunk_coord: Vector2i) -> void:
	var base = chunk_coord * CHUNK_SIZE
	var tiles: Dictionary = {}
	# One upfront lookup; null means no broken cells in this chunk's group (fast path).
	var chunk_broken: Variant = broken_by_group.get(_chunk_to_break_group(chunk_coord))
	for lx in CHUNK_SIZE:
		var col_x: int = base.x + lx
		var surface_y: int = _surface_y(col_x)
		for ly in CHUNK_SIZE:
			var cell := Vector2i(col_x, base.y + ly)
			if cell.y < 0 or cell.y >= world_thickness:
				continue
			if cell.y < surface_y:
				continue # above surface: sky
			# Unbreakable layer at the bottom of the world is always solid
			if cell.y == world_thickness - 1:
				var unbreakable_tile := _acquire_tile()
				unbreakable_tile.configure(Tile.Type.UNBREAKABLE, _cell_angle(cell), _cell_texture_index(cell), cell)
				unbreakable_tile.position = Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE / 2.0)
				add_child(unbreakable_tile)
				tiles[cell] = unbreakable_tile
				active_tiles[cell] = unbreakable_tile
				continue

			var depth: int = cell.y - surface_y
			var tile_type: int = _tile_type_for(cell, depth)
			if tile_type == -1:
				continue

			# Skip cell if accumulated damage already destroys this tile type.
			if chunk_broken != null:
				var hp_lost: int = chunk_broken.get(cell, 0)
				if hp_lost >= Tile.HP[tile_type]:
					continue

			var tile := _acquire_tile()
			tile.configure(tile_type, _cell_angle(cell), _cell_texture_index(cell), cell)
			tile.position = Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE / 2.0)
			add_child(tile)
			tiles[cell] = tile
			active_tiles[cell] = tile
	loaded_chunks[chunk_coord] = tiles

func _unload_chunk(chunk_coord: Vector2i) -> void:
	var chunk_tiles: Dictionary = loaded_chunks[chunk_coord]
	for cell in chunk_tiles:
		active_tiles.erase(cell)
		_release_tile(chunk_tiles[cell])
	loaded_chunks.erase(chunk_coord)


func break_cell(cell: Vector2i, damage: int = 1) -> void:
	_do_break(cell, damage, 0)

# Triggered by an explosive bullet upgrade. bonus_depth scales the blast radius via chain formula.
func bullet_explode(cell: Vector2i, bonus_depth: int = 0) -> void:
	_do_break(cell, EXPLOSION_OVERKILL, bonus_depth)
	_explode(cell, bonus_depth)

func _do_break(cell: Vector2i, damage: int, chain_depth: int) -> void:
	var chunk := _cell_to_chunk(cell)
	var group := _chunk_to_break_group(chunk)
	var group_broken: Dictionary = broken_by_group.get(group, {})
	var hp_lost: int = group_broken.get(cell, 0) + damage
	group_broken[cell] = hp_lost
	if not broken_by_group.has(group):
		broken_by_group[group] = group_broken

	if not active_tiles.has(cell):
		return
	var tile: Tile = active_tiles[cell]
	if tile.tile_type == Tile.Type.UNBREAKABLE:
		return
	if hp_lost < Tile.HP[tile.tile_type]:
		tile.animate_hit(hp_lost)
		return
	var was_explosive: bool = tile.tile_type == Tile.Type.EXPLOSIVE
	World.main.money += Tile.COIN_VALUES[tile.tile_type]
	active_tiles.erase(cell)
	if loaded_chunks.has(chunk):
		loaded_chunks[chunk].erase(cell)
	_release_tile(tile, true)

	if was_explosive:
		_explode(cell, chain_depth)

func _explode(center: Vector2i, chain_depth: int) -> void:
	var radius: float = terrain_config.explosion_base_radius + float(chain_depth) * terrain_config.explosion_chain_bonus
	_spawn_explosion_fx(center, radius)
	var r_int: int = ceili(radius)
	var r_sq: float = radius * radius
	var chained: Array[Vector2i] = []
	for dx in range(-r_int, r_int + 1):
		for dy in range(-r_int, r_int + 1):
			if dx == 0 and dy == 0:
				continue
			if dx * dx + dy * dy > r_sq:
				continue
			var target := center + Vector2i(dx, dy)
			if active_tiles.has(target) and active_tiles[target].tile_type == Tile.Type.EXPLOSIVE:
				chained.append(target)
			else:
				_do_break(target, EXPLOSION_OVERKILL, chain_depth + 1)

	if chained.is_empty():
		return
	await get_tree().process_frame # reduced lag
	for c in chained:
		_do_break(c, EXPLOSION_OVERKILL, chain_depth + 1)
		# await get_tree().process_frame # zero lag but ugly

func _spawn_explosion_fx(center: Vector2i, radius: float) -> void:
	Manager.audio.play_explosion_sfx()
	var p = World.explode_particle_pool.put_particle_at(Vector2(center.x * TILE_SIZE + TILE_SIZE / 2.0, center.y * TILE_SIZE + TILE_SIZE / 2.0))
	if not p:
		return
	p.amount = clampi(int(radius * 20), 20, 200)
	p.initial_velocity_min = 60.0 * radius
	p.initial_velocity_max = 160.0 * radius
	p.scale_amount_min = 0.01
	p.scale_amount_max = 0.3
	p.emitting = true

# Pool helpers: never queue_free tiles. Remove from tree and reuse later.
func _acquire_tile() -> Tile:
	if tile_pool.is_empty():
		return tile_scene.instantiate() as Tile
	return tile_pool.pop_back()

func _release_tile(tile: Tile, animate: bool = false) -> void:
	if animate:
		tile.animate_break()
	remove_child(tile)
	tile_pool.append(tile)

func break_cell_at_world_pos(world_pos: Vector2, damage: int = 1) -> void:
	break_cell(Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE)), damage)

func _cell_to_chunk(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / CHUNK_SIZE), floori(float(cell.y) / CHUNK_SIZE))

func _chunk_to_break_group(chunk: Vector2i) -> Vector2i:
	return Vector2i(floori(float(chunk.x) / BREAK_GROUP_CHUNKS), floori(float(chunk.y) / BREAK_GROUP_CHUNKS))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and World.main.dev_mode:
		if event.keycode == KEY_F1:
			World.camera.toggle_free_cam()
		elif event.keycode == KEY_F2:
			World.main.money = 1_000_000_000
		elif event.keycode == KEY_F4:
			# Max out everything
			World.main.damage = 999
			World.main.jetpackspeed = 1400
			World.main.width = 3.14
			World.main.particles_per_second = 1000
			World.main.particle_speed = 2000
			World.main.bullet_explosive_chance_level = 100
			World.main.bullet_explosive_size_level = 100

func _surface_y(x: int) -> int:
	return roundi(terrain_config.surface_base + surface_noise.get_noise_1d(x) * terrain_config.surface_amplitude)

func _tile_type_for(cell: Vector2i, depth: int) -> int:
	if depth == 0:
		return Tile.Type.GRASS
		
	var target_layer: Layer = null
	var current_depth_thresh := 0
	
	for layer: Layer in terrain_config.layers:
		current_depth_thresh += layer.thickness
		if depth <= current_depth_thresh:
			target_layer = layer
			break
			
	if target_layer == null:
		target_layer = terrain_config.layers[-1] as Layer

	var current_config: Patch = null
	var resolved_type: int = target_layer.type

	# Evaluate patches recursively
	var patches_to_check: Array = target_layer.patches
	while not patches_to_check.is_empty():
		var matched_patch: Patch = null
		for patch: Patch in patches_to_check:
			var patch_noise_gen: FastNoiseLite = patch.noise_gen.noise if patch.noise_gen != null else null
			var thresh: float = patch.threshold
			var invert: bool = patch.invert
			if patch_noise_gen:
				var val = patch_noise_gen.get_noise_2d(cell.x, cell.y)
				if (invert and val < thresh) or (not invert and val >= thresh):
					matched_patch = patch
					break # Enter the first matching patch
		
		if matched_patch:
			current_config = matched_patch
			resolved_type = current_config.type
			patches_to_check = current_config.patches
		else:
			break # No patch matched, stop digging deeper

	return resolved_type

func _cell_angle(cell: Vector2i) -> float:
	# Deterministic per-cell rotation so revisiting a chunk looks identical.
	var h: int = hash(Vector2i(cell.x, cell.y)) ^ world_seed
	return (absi(h) % 10000) / 10000.0 * TAU

func _cell_texture_index(cell: Vector2i) -> int:
	# Deterministic per-cell stone-texture choice.
	var h: int = hash(Vector2i(cell.x, cell.y)) ^ world_seed ^ 0xA5A5A5A5
	return absi(h) % 6

func _update_sky(world_y: float) -> void:
	var y_tiles: float = world_y / float(TILE_SIZE)
	
	var stops: Array[Dictionary] = [
		{"y": float(terrain_config.surface_base - 5), "color": terrain_config.surface_background_color}
	]
	
	var current_y = terrain_config.surface_base
	for layer: Layer in terrain_config.layers:
		current_y += layer.thickness
		var y_stop = current_y - layer.thickness * 0.5
		var col = layer.background
		stops.append({"y": float(y_stop), "color": col})
		
	stops.append({"y": float(world_thickness), "color": terrain_config.depths_background_color})

	var sky_color = terrain_config.depths_background_color
	if y_tiles <= stops[0].y:
		sky_color = stops[0].color
	elif y_tiles >= stops[stops.size() - 1].y:
		sky_color = stops[stops.size() - 1].color
	else:
		for i in range(stops.size() - 1):
			if y_tiles >= stops[i].y and y_tiles <= stops[i + 1].y:
				var t = (y_tiles - stops[i].y) / (stops[i + 1].y - stops[i].y)
				sky_color = stops[i].color.lerp(stops[i + 1].color, t)
				break
	
	RenderingServer.set_default_clear_color(sky_color)
	
	var vignette_node = World.main.get_node_or_null("WorldUI/Vignette")
	if vignette_node:
		var t_vignette: float = clampf((0.98 - (world_thickness - y_tiles) / world_thickness) ** 0.3, 0.0, 1.0)
		vignette_node.material.set_shader_parameter("vignette_strength", t_vignette * 1.5)
