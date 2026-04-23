extends Node2D

const TILE_SIZE := 16

# Tune these for performance. Fewer/smaller chunks = fewer loaded tiles.
const CHUNK_SIZE := 8
const LOAD_RADIUS_X := 5
const LOAD_RADIUS_Y := 3
const FREE_CAM_RADIUS_MULT := 2.0  # freecam loads a wider area for debugging

const WORLD_Y_MIN := 0
const WORLD_Y_MAX := 500

const AIR_THRESHOLD := -0.45
const HEAVY_THRESHOLD := 0.3

const CAVE_SPARSITY := 0.9
const CAVE_STRENGTH := 7.0
# Caves only form where bulk noise is already leaning toward air.
# At bulk <= CAVE_GATE_SOFT: full carving. At bulk >= CAVE_GATE_HARD: no carving.
const CAVE_GATE_SOFT := -0.25
const CAVE_GATE_HARD := 0.2

# Surface terrain shape. SURFACE_BASE is the average surface y (in tiles).
# SURFACE_AMPLITUDE is how far above/below surface can vary.
const SURFACE_BASE := 15
const SURFACE_AMPLITUDE := 6

# Layer depths below the surface.
const DIRT_DEPTH := 50
const STONE_TIER_HEIGHT := 90  # each of the 5 stone tiers spans this many cells

# Broken-cell storage grouping: each group spans BREAK_GROUP_CHUNKS x BREAK_GROUP_CHUNKS chunks.
# Coarser groups = fewer outer dict entries as the world fills up with mined cells.
const BREAK_GROUP_CHUNKS := 8

const STONE_TYPES := [
	Tile.Type.STONE_1,
	Tile.Type.STONE_2,
	Tile.Type.STONE_3,
	Tile.Type.STONE_4,
	Tile.Type.STONE_5,
]

const SKY_HIGH := Color(0.45, 0.7, 0.9)
const SKY_LOW := Color(0.08, 0.08, 0.10)
const SKY_DEPTH_START := 0
const SKY_DEPTH_END := 400

# Spawn the player near the bottom of the world inside a pre-carved pocket.
const SPAWN_CELL := Vector2i(0, 470)
const SPAWN_CLEAR_RADIUS := 5

var world_seed: int
var noise: FastNoiseLite
var cave_noise: FastNoiseLite
var surface_noise: FastNoiseLite
var gold_noise: FastNoiseLite
var diamond_noise: FastNoiseLite
var emerald_noise: FastNoiseLite
var explosive_noise: FastNoiseLite
var loaded_chunks: Dictionary = {}  # Vector2i chunk -> Dictionary[cell, Tile] (O(1) break removal)
var active_tiles: Dictionary = {}   # Vector2i cell -> Tile (fast break lookup)
# Per-cell damage, grouped by break-group coord: group -> Dictionary[cell, hp_lost].
# A cell is fully broken once its hp_lost >= Tile.HP[tile_type]. Partial damage persists
# across chunk unload/reload so a half-mined block stays half-mined.
var broken_by_group: Dictionary = {}

var tile_pool: Array[Tile] = []

@onready var the_guy: Node2D = $TheGuy
@onready var free_cam: Camera2D = $FreeCam
var _last_streamed_chunk: Vector2i = Vector2i(-2147483648, -2147483648)

func _ready() -> void:
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

	gold_noise = FastNoiseLite.new()
	gold_noise.seed = world_seed ^ 0xA1B2C3D4
	gold_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	gold_noise.frequency = 0.08

	diamond_noise = FastNoiseLite.new()
	diamond_noise.seed = world_seed ^ 0xB2C3D4E5
	diamond_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	diamond_noise.frequency = 0.12

	emerald_noise = FastNoiseLite.new()
	emerald_noise.seed = world_seed ^ 0xC3D4E5F6
	emerald_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	emerald_noise.frequency = 0.14

	explosive_noise = FastNoiseLite.new()
	explosive_noise.seed = world_seed ^ 0xD4E5F607
	explosive_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	explosive_noise.frequency = 0.15

	_setup_lava()

	_clear_spawn_area(SPAWN_CELL, SPAWN_CLEAR_RADIUS)
	var spawn_world: Vector2 = Vector2(SPAWN_CELL) * TILE_SIZE
	if the_guy:
		the_guy.global_position = spawn_world
	update_region(spawn_world)

func _process(_delta: float) -> void:
	var tracking_pos: Vector2
	if free_cam.is_current():
		tracking_pos = free_cam.global_position
		# Freecam debug: click or hold left mouse to delete blocks under the cursor.
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break_cell_at_world_pos(get_global_mouse_position(), EXPLOSION_OVERKILL)
	elif the_guy:
		tracking_pos = the_guy.global_position
	else:
		return
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
				group_broken[cell] = 99999  # well above any tile's HP → always broken
				if not broken_by_group.has(group):
					broken_by_group[group] = group_broken

const LAVA_SHADER_CODE := """
shader_type canvas_item;

uniform vec4 dark_color : source_color = vec4(0.7, 0.2, 0.0, 1.0);
uniform vec4 bright_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);

varying vec2 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	world_pos = VERTEX;
}

void fragment() {
	float t = TIME * 0.4;
	vec2 p = world_pos * 0.008;
	float n = vnoise(p + vec2(t * 0.3, t * 0.2));
	n = mix(n, vnoise(p * 2.0 - vec2(t * 0.6, t * 0.1)), 0.4);
	COLOR = mix(dark_color, bright_color, n);
}
"""

func _setup_lava() -> void:
	var lava := Polygon2D.new()
	var top: float = WORLD_Y_MAX * TILE_SIZE
	var half_width: float = 100000.0
	var depth: float = 4000.0
	lava.polygon = PackedVector2Array([
		Vector2(-half_width, top),
		Vector2(half_width, top),
		Vector2(half_width, top + depth),
		Vector2(-half_width, top + depth),
	])
	var shader := Shader.new()
	shader.code = LAVA_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	lava.material = mat
	lava.z_index = -10
	add_child(lava)

func update_region(world_pos: Vector2) -> void:
	_update_sky(world_pos.y)
	var rx := LOAD_RADIUS_X
	var ry := LOAD_RADIUS_Y
	if free_cam != null and free_cam.is_current():
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
	var base := chunk_coord * CHUNK_SIZE
	var tiles: Dictionary = {}
	# One upfront lookup; null means no broken cells in this chunk's group (fast path).
	var chunk_broken: Variant = broken_by_group.get(_chunk_to_break_group(chunk_coord))
	for lx in CHUNK_SIZE:
		var col_x: int = base.x + lx
		var surface_y: int = _surface_y(col_x)
		for ly in CHUNK_SIZE:
			var cell := Vector2i(col_x, base.y + ly)
			if cell.y < WORLD_Y_MIN or cell.y > WORLD_Y_MAX:
				continue
			if cell.y < surface_y:
				continue  # above surface: sky
			var bulk := noise.get_noise_2d(cell.x, cell.y)
			var cave := _cave_at(cell)
			var cave_penalty: float = maxf(cave - CAVE_SPARSITY, 0.0) * CAVE_STRENGTH
			var cave_gate: float = clampf((CAVE_GATE_HARD - bulk) / (CAVE_GATE_HARD - CAVE_GATE_SOFT), 0.0, 1.0)
			var combined: float = bulk - cave_penalty * cave_gate
			if combined < AIR_THRESHOLD:
				continue

			var depth: int = cell.y - surface_y
			var is_heavy: bool = combined >= HEAVY_THRESHOLD
			var tile_type: Tile.Type = _tile_type_for(cell, depth, is_heavy)

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

const EXPLOSION_BASE_RADIUS := 3.0
const EXPLOSION_CHAIN_BONUS := 0.55
const EXPLOSION_CHAIN_DELAY := 0.08  # seconds between successive chain waves
const EXPLOSION_OVERKILL := 999999

func break_cell(cell: Vector2i, damage: int = 1) -> void:
	_do_break(cell, damage, 0)

# Triggered by an explosive bullet upgrade. bonus_depth scales the blast radius via chain formula.
func bullet_explode(cell: Vector2i, bonus_depth: int = 0) -> void:
	var center_was_explosive: bool = active_tiles.has(cell) and active_tiles[cell].tile_type == Tile.Type.EXPLOSIVE
	_do_break(cell, EXPLOSION_OVERKILL, bonus_depth)
	if not center_was_explosive:
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
	if hp_lost < Tile.HP[tile.tile_type]:
		return

	var was_explosive: bool = tile.tile_type == Tile.Type.EXPLOSIVE
	Global.money += Tile.COIN_VALUES[tile.tile_type]
	active_tiles.erase(cell)
	if loaded_chunks.has(chunk):
		loaded_chunks[chunk].erase(cell)
	_release_tile(tile)

	if was_explosive:
		_explode(cell, chain_depth)

func _explode(center: Vector2i, chain_depth: int) -> void:
	var radius: float = EXPLOSION_BASE_RADIUS + float(chain_depth) * EXPLOSION_CHAIN_BONUS
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
	await get_tree().create_timer(EXPLOSION_CHAIN_DELAY).timeout
	for c in chained:
		_do_break(c, EXPLOSION_OVERKILL, chain_depth + 1)

func _spawn_explosion_fx(center: Vector2i, radius: float) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(center.x * TILE_SIZE + TILE_SIZE / 2.0, center.y * TILE_SIZE + TILE_SIZE / 2.0)
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = clampi(int(radius * 10), 20, 200)
	p.lifetime = 0.45
	p.spread = 180.0
	p.initial_velocity_min = 60.0 * radius
	p.initial_velocity_max = 160.0 * radius
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0 + radius
	p.damping_min = 80.0
	p.damping_max = 160.0
	var ramp := Gradient.new()
	ramp.add_point(0.0, Color(1.0, 0.95, 0.4, 1.0))
	ramp.add_point(0.25, Color(1.0, 0.5, 0.1, 0.95))
	ramp.add_point(0.7, Color(0.5, 0.15, 0.05, 0.5))
	ramp.add_point(1.0, Color(0.1, 0.05, 0.05, 0.0))
	p.color_ramp = ramp
	p.z_index = 5
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

# Pool helpers: never queue_free tiles. Remove from tree and reuse later.
func _acquire_tile() -> Tile:
	if tile_pool.is_empty():
		return Tile.new()
	return tile_pool.pop_back()

func _release_tile(tile: Tile) -> void:
	remove_child(tile)
	tile_pool.append(tile)

func break_cell_at_world_pos(world_pos: Vector2, damage: int = 1) -> void:
	break_cell(Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE)), damage)

func _cell_to_chunk(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / CHUNK_SIZE), floori(float(cell.y) / CHUNK_SIZE))

func _chunk_to_break_group(chunk: Vector2i) -> Vector2i:
	return Vector2i(floori(float(chunk.x) / BREAK_GROUP_CHUNKS), floori(float(chunk.y) / BREAK_GROUP_CHUNKS))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_toggle_free_cam()
		elif event.keycode == KEY_F2:
			Global.money = 1_000_000_000

func _toggle_free_cam() -> void:
	var player_cam: Camera2D = the_guy.get_node("Camera2D")
	if free_cam.is_current():
		player_cam.make_current()
		free_cam.enabled = false
	else:
		free_cam.global_position = player_cam.global_position
		free_cam.enabled = true
		free_cam.make_current()
	# Force a region refresh so the expanded/contracted radius takes effect immediately.
	_last_streamed_chunk = Vector2i(-2147483648, -2147483648)

func _surface_y(x: int) -> int:
	return roundi(SURFACE_BASE + surface_noise.get_noise_1d(x) * SURFACE_AMPLITUDE)

func _tile_type_for(cell: Vector2i, depth: int, is_heavy: bool) -> Tile.Type:
	if depth == 0:
		return Tile.Type.GRASS
	if depth <= DIRT_DEPTH:
		return Tile.Type.DIRT
	# height_ratio = 0 at the bottom (start), 1 at the top (endgame).
	var height_ratio: float = clampf(1.0 - float(cell.y) / float(WORLD_Y_MAX), 0.0, 1.0)
	# Explosives appear only in the stone zone; a touch more common as we go up.
	var explosive_threshold: float = 0.49 - height_ratio * 0.10
	if explosive_noise.get_noise_2d(cell.x, cell.y) > explosive_threshold:
		return Tile.Type.EXPLOSIVE
	# Compute underlying stone tier; some ores are gated on it.
	var below_dirt: int = depth - DIRT_DEPTH - 1
	var stone_num: int = clampi(below_dirt / STONE_TIER_HEIGHT + 1, 1, 5)
	if is_heavy and stone_num < 5:  # emerald never spawns in the deepest tier
		var emerald_threshold: float = 0.48 - height_ratio * 0.28  # a touch rarer at the bottom
		if emerald_noise.get_noise_2d(cell.x, cell.y) > emerald_threshold:
			return Tile.Type.EMERALD
	var diamond_threshold: float = 0.45 - height_ratio * 0.15
	if is_heavy:
		diamond_threshold -= 0.12  # more common inside heavy rock pouches
	if diamond_noise.get_noise_2d(cell.x, cell.y) > diamond_threshold:
		return Tile.Type.DIAMOND
	var gold_threshold: float = 0.35 + height_ratio * 0.10  # rarer / smaller veins near top
	if gold_noise.get_noise_2d(cell.x, cell.y) > gold_threshold:
		return Tile.Type.GOLD
	# Dark spot: a heavy cell in stone N shows the previous (darker) tier.
	if is_heavy and stone_num > 1:
		stone_num -= 1
	return STONE_TYPES[stone_num - 1]

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
	var y_tiles: float = world_y / TILE_SIZE
	var t: float = clampf((y_tiles - SKY_DEPTH_START) / float(SKY_DEPTH_END - SKY_DEPTH_START), 0.0, 1.0)
	RenderingServer.set_default_clear_color(SKY_HIGH.lerp(SKY_LOW, t))
