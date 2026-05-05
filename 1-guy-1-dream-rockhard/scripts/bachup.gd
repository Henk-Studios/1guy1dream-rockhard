extends Node2D
const TILE_SIZE := 16

var terrain_config: Dictionary = {
	"chunk_size": 8,
	"load_radius_x": 5,
	"load_radius_y": 3,
	"free_cam_radius_mult": 2.0,
	"world_y_min": 0,
	"world_y_max": 500,
	"air_threshold": - 0.45,
	"heavy_threshold": 0.3,
	"cave_sparsity": 0.9,
	"cave_strength": 7.0,
	"cave_gate_soft": - 0.25,
	"cave_gate_hard": 0.2,
	"surface_base": 15,
	"surface_amplitude": 6,
	"break_group_chunks": 8,
	"spawn_cell": Vector2i(0, 470),
	"spawn_clear_radius": 5,
	"surface_background_color": Color(0.45, 0.7, 0.9),
	"depths_background_color": Color(0.08, 0.08, 0.10),
	"explosion_base_radius": 3.0,
	"explosion_chain_bonus": 0.55,
	"explosion_chain_delay": 0.08,
	"explosion_overkill": 999999,

	"layers": [
		{
			"type": Tile.Type.DIRT,
			"thickness": 50,
			"background": Color(0.09, 0.07, 0.04),
			"patches": [
				{
					"noise_freq": 0.15,
					"seed_offset": 0xD4E5F607,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.49,
					"type": Tile.Type.EXPLOSIVE,
				},
				{
					"noise_freq": 0.08,
					"seed_offset": 0xA1B2C3D4,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.35,
					"type": Tile.Type.GOLD,
				}
			]
		},
		{
			"type": Tile.Type.STONE_1,
			"thickness": 90,
			"background": Color(0.08, 0.08, 0.10),
			"patches": [
				{
					"noise_freq": 0.05,
					"seed_offset": 0x87654321,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.3,
					"type": Tile.Type.STONE_2,
					"patches": []
				},
				{
					"noise_freq": 0.15,
					"seed_offset": 0xD4E5F607,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.49,
					"type": Tile.Type.EXPLOSIVE,
				},
				{
					"noise_freq": 0.08,
					"seed_offset": 0xA1B2C3D4,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.35,
					"type": Tile.Type.GOLD,
				},
				{
					"noise_freq": 0.12,
					"seed_offset": 0xB2C3D4E5,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.45,
					"type": Tile.Type.DIAMOND,
				}
			]
		},
		{
			"type": Tile.Type.STONE_2,
			"thickness": 90,
			"background": Color(0.07, 0.07, 0.09),
			"patches": [
				{
					"noise_freq": 0.05,
					"seed_offset": 0x87654321,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.3,
					"type": Tile.Type.STONE_3,
					"patches": []
				},
				{
					"noise_freq": 0.15,
					"seed_offset": 0xD4E5F607,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.49,
					"type": Tile.Type.EXPLOSIVE,
				},
				{
					"noise_freq": 0.08,
					"seed_offset": 0xA1B2C3D4,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.35,
					"type": Tile.Type.GOLD,
				},
				{
					"noise_freq": 0.12,
					"seed_offset": 0xB2C3D4E5,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.45,
					"type": Tile.Type.DIAMOND,
				}
			]
		},
		{
			"type": Tile.Type.STONE_3,
			"thickness": 90,
			"background": Color(0.06, 0.06, 0.08),
			"patches": [
				{
					"noise_freq": 0.05,
					"seed_offset": 0x87654321,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.3,
					"type": Tile.Type.STONE_4,
					"patches": []
				},
				{
					"noise_freq": 0.15,
					"seed_offset": 0xD4E5F607,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.49,
					"type": Tile.Type.EXPLOSIVE,
				},
				{
					"noise_freq": 0.08,
					"seed_offset": 0xA1B2C3D4,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.35,
					"type": Tile.Type.GOLD,
				},
				{
					"noise_freq": 0.12,
					"seed_offset": 0xB2C3D4E5,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.45,
					"type": Tile.Type.DIAMOND,
				}
			]
		},
		{
			"type": Tile.Type.STONE_4,
			"thickness": 90,
			"background": Color(0.05, 0.05, 0.07),
			"patches": [
				{
					"noise_freq": 0.05,
					"seed_offset": 0x87654321,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.3,
					"type": Tile.Type.STONE_5,
					"patches": []
				},
				{
					"noise_freq": 0.15,
					"seed_offset": 0xD4E5F607,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.49,
					"type": Tile.Type.EXPLOSIVE,
				},
				{
					"noise_freq": 0.08,
					"seed_offset": 0xA1B2C3D4,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.35,
					"type": Tile.Type.GOLD,
				},
				{
					"noise_freq": 0.12,
					"seed_offset": 0xB2C3D4E5,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.45,
					"type": Tile.Type.DIAMOND,
				}
			]
		},
		{
			"type": Tile.Type.STONE_5,
			"thickness": 90,
			"background": Color(0.04, 0.04, 0.06),
			"patches": [
				{
					"noise_freq": 0.05,
					"seed_offset": 0x87654321,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.3,
					"type": Tile.Type.STONE_1,
					"patches": []
				},
				{
					"noise_freq": 0.15,
					"seed_offset": 0xD4E5F607,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.49,
					"type": Tile.Type.EXPLOSIVE,
				},
				{
					"noise_freq": 0.08,
					"seed_offset": 0xA1B2C3D4,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.35,
					"type": Tile.Type.GOLD,
				},
				{
					"noise_freq": 0.12,
					"seed_offset": 0xB2C3D4E5,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.45,
					"type": Tile.Type.DIAMOND,
				},
				{
					"noise_freq": 0.14,
					"seed_offset": 0xC3D4E5F6,
					"noise_type": FastNoiseLite.TYPE_PERLIN,
					"threshold": 0.48,
					"type": Tile.Type.EMERALD,
				}
			]
		}
	]
}

# Tune these for performance. Fewer/smaller chunks = fewer loaded tiles.


# Caves only form where bulk noise is already leaning toward air.
# At bulk <= terrain_config.cave_gate_soft: full carving. At bulk >= terrain_config.cave_gate_hard: no carving.

# Surface terrain shape. terrain_config.surface_base is the average surface y (in tiles).
# terrain_config.surface_amplitude is how far above/below surface can vary.

# Layer depths below the surface.

# Broken-cell storage grouping: each group spans terrain_config.break_group_chunks x terrain_config.break_group_chunks chunks.
# Coarser groups = fewer outer dict entries as the world fills up with mined cells.
const STONE_TYPES := [
	Tile.Type.STONE_1,
	Tile.Type.STONE_2,
	Tile.Type.STONE_3,
	Tile.Type.STONE_4,
	Tile.Type.STONE_5,
]


# Spawn the player near the bottom of the world inside a pre-carved pocket.

@export var tile_scene: PackedScene

var world_seed: int
var noise: FastNoiseLite
var cave_noise: FastNoiseLite
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

	noise = FastNoiseLite.new()
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.015

	cave_noise = FastNoiseLite.new()
	cave_noise.seed = world_seed ^ 0x9E3779B9
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	cave_noise.fractal_octaves = 1
	cave_noise.frequency = 0.05

	surface_noise = FastNoiseLite.new()
	surface_noise.seed = world_seed ^ 0x12345678
	surface_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	surface_noise.frequency = 0.03

	_setup_patches_recursive(terrain_config.layers)

	_setup_lava()

	_clear_spawn_area(terrain_config.spawn_cell, terrain_config.spawn_clear_radius)
	var spawn_world: Vector2 = Vector2(terrain_config.spawn_cell) * TILE_SIZE
	World.the_guy.global_position = spawn_world
	update_region(spawn_world)
	Manager.scene.finish_loading()

func _setup_patches_recursive(items: Array) -> void:
	for item in items:
		if item.has("patches"):
			for patch in item["patches"]:
				var p_noise := FastNoiseLite.new()
				p_noise.seed = world_seed ^ patch.get("seed_offset", 0)
				p_noise.noise_type = patch.get("noise_type", FastNoiseLite.TYPE_PERLIN)
				p_noise.frequency = patch.get("noise_freq", 0.05)
				patch["noise_gen"] = p_noise
				
				if patch.has("patches"):
					_setup_patches_recursive([patch])

func _process(_delta: float) -> void:
	var tracking_pos: Vector2
	if World.camera.free_cam_enabled:
		tracking_pos = World.camera.global_position
		# Freecam debug: click or hold left mouse to delete blocks under the cursor.
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break_cell_at_world_pos(get_global_mouse_position(), terrain_config.explosion_overkill)
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
				group_broken[cell] = 99999 # well above any tile's HP → always broken
				if not broken_by_group.has(group):
					broken_by_group[group] = group_broken

func _setup_lava() -> void:
	World.lava.position.y = (terrain_config.world_y_max + 1) * TILE_SIZE

func update_region(world_pos: Vector2) -> void:
	var rx = terrain_config.load_radius_x
	var ry = terrain_config.load_radius_y
	if World.camera.free_cam_enabled:
		rx = roundi(terrain_config.load_radius_x * terrain_config.free_cam_radius_mult)
		ry = roundi(terrain_config.load_radius_y * terrain_config.free_cam_radius_mult)
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
	var chunk_pixels: float = terrain_config.chunk_size * TILE_SIZE
	return Vector2i(floor(world_pos.x / chunk_pixels), floor(world_pos.y / chunk_pixels))

func _generate_chunk(chunk_coord: Vector2i) -> void:
	var base = chunk_coord * terrain_config.chunk_size
	var tiles: Dictionary = {}
	# One upfront lookup; null means no broken cells in this chunk's group (fast path).
	var chunk_broken: Variant = broken_by_group.get(_chunk_to_break_group(chunk_coord))
	for lx in terrain_config.chunk_size:
		var col_x: int = base.x + lx
		var surface_y: int = _surface_y(col_x)
		for ly in terrain_config.chunk_size:
			var cell := Vector2i(col_x, base.y + ly)
			if cell.y < terrain_config.world_y_min or cell.y > terrain_config.world_y_max:
				continue
			if cell.y < surface_y:
				continue # above surface: sky
			# Unbreakable layer at the bottom of the world is always solid
			if cell.y == terrain_config.world_y_max:
				var unbreakable_tile := _acquire_tile()
				unbreakable_tile.configure(Tile.Type.UNBREAKABLE, _cell_angle(cell), _cell_texture_index(cell), cell)
				unbreakable_tile.position = Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE / 2.0)
				add_child(unbreakable_tile)
				tiles[cell] = unbreakable_tile
				active_tiles[cell] = unbreakable_tile
				continue

			var bulk := noise.get_noise_2d(cell.x, cell.y)
			var cave := _cave_at(cell)
			var cave_penalty: float = maxf(cave - terrain_config.cave_sparsity, 0.0) * terrain_config.cave_strength
			var cave_gate: float = clampf((terrain_config.cave_gate_hard - bulk) / (terrain_config.cave_gate_hard - terrain_config.cave_gate_soft), 0.0, 1.0)
			var combined: float = bulk - cave_penalty * cave_gate
			if combined < terrain_config.air_threshold:
				continue

			var depth: int = cell.y - surface_y
			var tile_type: Tile.Type = _tile_type_for(cell, depth)

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
	_do_break(cell, terrain_config.explosion_overkill, bonus_depth)
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
	Global.money += Tile.COIN_VALUES[tile.tile_type]
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
				_do_break(target, terrain_config.explosion_overkill, chain_depth + 1)

	if chained.is_empty():
		return
	await get_tree().process_frame # reduced lag
	for c in chained:
		_do_break(c, terrain_config.explosion_overkill, chain_depth + 1)
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
	return Vector2i(floori(float(cell.x) / terrain_config.chunk_size), floori(float(cell.y) / terrain_config.chunk_size))

func _chunk_to_break_group(chunk: Vector2i) -> Vector2i:
	return Vector2i(floori(float(chunk.x) / terrain_config.break_group_chunks), floori(float(chunk.y) / terrain_config.break_group_chunks))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and Global.dev_mode:
		if event.keycode == KEY_F1:
			World.camera.toggle_free_cam()
		elif event.keycode == KEY_F2:
			Global.money = 1_000_000_000
		elif event.keycode == KEY_F4:
			# Max out everything
			Global.damage = 999
			Global.jetpackspeed = 1400
			Global.width = 3.14
			Global.particles_per_second = 1000
			Global.particle_speed = 2000
			Global.bullet_explosive_chance_level = 100
			Global.bullet_explosive_size_level = 100

func _surface_y(x: int) -> int:
	return roundi(terrain_config.surface_base + surface_noise.get_noise_1d(x) * terrain_config.surface_amplitude)

func _tile_type_for(cell: Vector2i, depth: int) -> Tile.Type:
	if depth == 0:
		return Tile.Type.GRASS
		
	var target_layer: Dictionary
	var current_depth_thresh := 0
	
	for layer in terrain_config.layers:
		current_depth_thresh += layer.thickness
		if depth <= current_depth_thresh:
			target_layer = layer
			break
			
	if target_layer.is_empty():
		target_layer = terrain_config.layers[-1]

	var current_config: Dictionary = target_layer
	var resolved_type: Tile.Type = current_config.type

	# Evaluate patches recursively
	var patches_to_check: Array = current_config.get("patches", [])
	while not patches_to_check.is_empty():
		var matched_patch = null
		for patch in patches_to_check:
			var patch_noise_gen: FastNoiseLite = patch.get("noise_gen")
			var thresh: float = patch.get("threshold", 0.3)
			if patch_noise_gen and patch_noise_gen.get_noise_2d(cell.x, cell.y) >= thresh:
				matched_patch = patch
				break # Enter the first matching patch
		
		if matched_patch:
			current_config = matched_patch
			resolved_type = current_config.get("type", resolved_type)
			patches_to_check = current_config.get("patches", [])
		else:
			break # No patch matched, stop digging deeper

	return resolved_type

func _cave_at(cell: Vector2i) -> float:
	# Dilated ridge sample: cell counts as "on a ridge" if it or any 4-neighbor has a peak.
	# Thickens tunnels without increasing their count or length.
	var m := cave_noise.get_noise_2d(cell.x, cell.y)
	m = maxf(m, cave_noise.get_noise_2d(cell.x - 1, cell.y))
	m = maxf(m, cave_noise.get_noise_2d(cell.x + 1, cell.y))
	m = maxf(m, cave_noise.get_noise_2d(cell.x, cell.y - 1))
	m = maxf(m, cave_noise.get_noise_2d(cell.x, cell.y + 1))
	return m

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
	for layer in terrain_config.layers:
		current_y += layer.thickness
		var y_stop = current_y - layer.thickness * 0.5
		var col = layer.background
		if col.a == 0.0:
			col = Tile.COLORS[layer.type].darkened(0.8)
		stops.append({"y": float(y_stop), "color": col})
		
	stops.append({"y": float(terrain_config.world_y_max), "color": terrain_config.depths_background_color})

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
	
	var vignette_node = get_node_or_null("WorldUI/Vignette")
	if vignette_node:
		var t_vignette: float = clampf((y_tiles - terrain_config.surface_base) / float(terrain_config.world_y_max - terrain_config.surface_base), 0.0, 1.0)
		vignette_node.material.set_shader_parameter("vignette_strength", t_vignette * 1.5)
