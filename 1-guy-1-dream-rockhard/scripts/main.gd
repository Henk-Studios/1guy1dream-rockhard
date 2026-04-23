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
const STONE_TIER_HEIGHT := 90  # each of the 5 stone tiers spans this many cells

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

var world_seed: int
var noise: FastNoiseLite
var cave_noise: FastNoiseLite
var surface_noise: FastNoiseLite
var loaded_chunks: Dictionary = {}  # Vector2i -> Array[Tile]

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

	update_region(Vector2.ZERO)

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
	var tiles: Array = []
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
			var tile_type: Tile.Type = _tile_type_for(depth, is_heavy)

			var tile := Tile.new()
			tile.configure(tile_type, _cell_angle(cell), _cell_texture_index(cell))
			tile.position = Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE / 2.0)
			add_child(tile)
			tiles.append(tile)
	loaded_chunks[chunk_coord] = tiles

func _unload_chunk(chunk_coord: Vector2i) -> void:
	for tile in loaded_chunks[chunk_coord]:
		tile.queue_free()
	loaded_chunks.erase(chunk_coord)

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
