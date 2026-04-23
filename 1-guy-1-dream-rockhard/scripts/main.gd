extends Node2D

const TILE_SIZE := 16

# Tune these for performance. Fewer/smaller chunks = fewer loaded tiles.
const CHUNK_SIZE := 8
const LOAD_RADIUS_X := 4 # original is 3
const LOAD_RADIUS_Y := 2 # original is 2

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
const STONE_TIER_HEIGHT := 90 # each of the 5 stone tiers spans this many cells

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
var loaded_chunks: Dictionary = {} # Vector2i chunk -> Dictionary[cell, Tile] (O(1) break removal)
var active_tiles: Dictionary = {} # Vector2i cell -> Tile (fast break lookup)
# Per-cell damage, grouped by break-group coord: group -> Dictionary[cell, hp_lost].
# A cell is fully broken once its hp_lost >= Tile.HP[tile_type]. Partial damage persists
# across chunk unload/reload so a half-mined block stays half-mined.
var broken_by_group: Dictionary = {}

var tile_pool: Array[Tile] = []

var fps_label: Label

@onready var the_guy: Node2D = $TheGuy
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

	_setup_fps_overlay()
	_setup_lava()

	_clear_spawn_area(SPAWN_CELL, SPAWN_CLEAR_RADIUS)
	var spawn_world: Vector2 = Vector2(SPAWN_CELL) * TILE_SIZE
	if the_guy:
		the_guy.global_position = spawn_world
	update_region(spawn_world)

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	if the_guy:
		_update_sky(the_guy.global_position.y)
		var chunk := _world_to_chunk(the_guy.global_position)
		if chunk != _last_streamed_chunk:
			_last_streamed_chunk = chunk
			update_region(the_guy.global_position)

func _clear_spawn_area(center: Vector2i, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var cell := center + Vector2i(dx, dy)
				var group := _chunk_to_break_group(_cell_to_chunk(cell))
				var group_broken: Dictionary = broken_by_group.get(group, {})
<< << << < HEAD
				group_broken[cell] = 99999 # well above any tile's HP → always broken
== == == =
				group_broken[cell] = 99999 # well above any tile's HP → always broken
>> >> >> > pascal - 2
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

func _setup_fps_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	fps_label = Label.new()
	fps_label.position = Vector2(8, 4)
	fps_label.add_theme_color_override("font_color", Color.WHITE)
	fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	fps_label.add_theme_constant_override("outline_size", 4)
	fps_label.add_theme_font_size_override("font_size", 20)
	layer.add_child(fps_label)

func update_region(world_pos: Vector2) -> void:
	_update_sky(world_pos.y)
	var center := _world_to_chunk(world_pos)
	var wanted: Dictionary = {}
	for dx in range(-LOAD_RADIUS_X, LOAD_RADIUS_X + 1):
		for dy in range(-LOAD_RADIUS_Y, LOAD_RADIUS_Y + 1):
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
<< << << < HEAD
				continue # above surface: sky
== == == =
				continue # above surface: sky
>> >> >> > pascal - 2
			var bulk := noise.get_noise_2d(cell.x, cell.y)
			var cave := _cave_at(cell)
			var cave_penalty: float = maxf(cave - CAVE_SPARSITY, 0.0) * CAVE_STRENGTH
			var cave_gate: float = clampf((CAVE_GATE_HARD - bulk) / (CAVE_GATE_HARD - CAVE_GATE_SOFT), 0.0, 1.0)
			var combined: float = bulk - cave_penalty * cave_gate
			if combined < AIR_THRESHOLD:
				continue

			var depth: int = cell.y - surface_y
			var is_heavy: bool = combined >= HEAVY_THRESHOLD
			var tile_type: Tile.Type = _tile_type_for(depth, is_heavy)

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
	var chunk := _cell_to_chunk(cell)
	var group := _chunk_to_break_group(chunk)
	var group_broken: Dictionary = broken_by_group.get(group, {})
	var hp_lost: int = group_broken.get(cell, 0) + damage
	group_broken[cell] = hp_lost
	if not broken_by_group.has(group):
		broken_by_group[group] = group_broken
	if active_tiles.has(cell):
		var tile: Tile = active_tiles[cell]
		if hp_lost >= Tile.HP[tile.tile_type]:
			active_tiles.erase(cell)
			if loaded_chunks.has(chunk):
				loaded_chunks[chunk].erase(cell)
			_release_tile(tile)

# Pool helpers: never queue_free tiles. Remove from tree and reuse later.
func _acquire_tile() -> Tile:
	if tile_pool.is_empty():
		return Tile.new()
	return tile_pool.pop_back()

func _release_tile(tile: Tile) -> void:
	remove_child(tile)
	tile_pool.append(tile)

func break_cell_at_world_pos(world_pos: Vector2) -> void:
	break_cell(Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE)))

func _cell_to_chunk(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / CHUNK_SIZE), floori(float(cell.y) / CHUNK_SIZE))

func _chunk_to_break_group(chunk: Vector2i) -> Vector2i:
	return Vector2i(floori(float(chunk.x) / BREAK_GROUP_CHUNKS), floori(float(chunk.y) / BREAK_GROUP_CHUNKS))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		break_cell_at_world_pos(get_global_mouse_position())

func _surface_y(x: int) -> int:
	return roundi(SURFACE_BASE + surface_noise.get_noise_1d(x) * SURFACE_AMPLITUDE)

func _tile_type_for(depth: int, is_heavy: bool) -> Tile.Type:
	if depth == 0:
		return Tile.Type.GRASS
	if depth <= DIRT_DEPTH:
		return Tile.Type.DIRT
	# Stone zone: tier 1..5 by depth below dirt
	var below_dirt: int = depth - DIRT_DEPTH - 1
	var stone_num: int = clampi(below_dirt / STONE_TIER_HEIGHT + 1, 1, 5)
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
