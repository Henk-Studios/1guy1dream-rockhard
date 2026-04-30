extends Node2D

# Grid dimensions
const GRID_WIDTH := 16
const GRID_HEIGHT := 9
const TILE_SIZE := 64

# Scroll speed (pixels per second)
const SCROLL_SPEED := 80.0

# Noise configuration
const SURFACE_BASE := 15
const SURFACE_AMPLITUDE := 6

const AIR_THRESHOLD := -0.45
const HEAVY_THRESHOLD := 0.3

const CAVE_SPARSITY := 0.9
const CAVE_STRENGTH := 7.0
const CAVE_GATE_SOFT := -0.25
const CAVE_GATE_HARD := 0.2

const DIRT_DEPTH := 50
const STONE_TIER_HEIGHT := 90

const STONE_TYPES := [
	Tile.Type.STONE_1,
	Tile.Type.STONE_2,
	Tile.Type.STONE_3,
	Tile.Type.STONE_4,
	Tile.Type.STONE_5,
]

# Noise generators
var world_seed: int
var noise: FastNoiseLite
var cave_noise: FastNoiseLite
var surface_noise: FastNoiseLite
var gold_noise: FastNoiseLite
var diamond_noise: FastNoiseLite
var emerald_noise: FastNoiseLite
var explosive_noise: FastNoiseLite

# Grid tracking: maps world grid coordinates to Tile instances
var active_tiles: Dictionary = {} # Vector2i(grid_x, grid_y) -> Tile
var tile_pool: Array[Tile] = []

# Current scroll position (in world pixels)
var scroll_x: float = 0.0
var scroll_y: float = 0.0

# Track which grid cells have been generated to avoid duplicates
var generated_cells: Dictionary = {} # Vector2i(grid_x, grid_y) -> true

# Zoom scales with window width so every monitor shows the same slice of the world.
# REFERENCE_WIDTH is the resolution the game was tuned at; BASE_ZOOM is the zoom at that size.
const REFERENCE_WIDTH := 1152.0
const BASE_ZOOM := 0.9

@export var tile_scene: PackedScene

func _ready() -> void:
	world_seed = randi()
	_setup_noise()
	
	# Start at the bottom of the map
	scroll_y = 500.0 * TILE_SIZE # Start viewing from deep underground
	
	_apply_resolution_zoom()
	get_viewport().size_changed.connect(_apply_resolution_zoom)
	
	_generate_initial_grid()

func _setup_noise() -> void:
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

func _generate_initial_grid() -> void:
	# Generate tiles that cover the initial viewport
	var view_size: Vector2 = get_viewport_rect().size
	var grid_x_min: int = floori(scroll_x / TILE_SIZE) - 1
	var grid_x_max: int = floori((scroll_x + view_size.x) / TILE_SIZE) + 1
	var grid_y_min: int = floori(scroll_y / TILE_SIZE) - 1
	var grid_y_max: int = floori((scroll_y + view_size.y) / TILE_SIZE) + 1

	for grid_x in range(grid_x_min, grid_x_max + 1):
		for grid_y in range(grid_y_min, grid_y_max + 1):
			_generate_or_show_tile(grid_x, grid_y)

func _process(delta: float) -> void:
	# Update scroll position
	scroll_x += SCROLL_SPEED * delta
	scroll_y -= SCROLL_SPEED * delta

	# Generate or recycle tiles based on current scroll
	_update_visible_tiles()
	
	# Update all tile positions
	_update_tile_positions()

func _update_visible_tiles() -> void:
	# Clean up tiles that have scrolled too far off-screen
	var view_size: Vector2 = get_viewport_rect().size
	var tiles_to_remove: Array[Vector2i] = []
	for grid_cell in active_tiles.keys():
		var pixel_pos: Vector2 = _grid_to_pixel(grid_cell)
		# Remove tiles that are far off any edge of the screen
		if pixel_pos.x < -TILE_SIZE or pixel_pos.x > view_size.x + TILE_SIZE or \
		   pixel_pos.y < -TILE_SIZE or pixel_pos.y > view_size.y + TILE_SIZE:
			tiles_to_remove.append(grid_cell)
	
	for cell in tiles_to_remove:
		_release_tile(active_tiles[cell])
		active_tiles.erase(cell)
		generated_cells.erase(cell)

	# Generate new tiles that have scrolled into view (with margin to prevent gaps)
	var grid_x_min: int = floori(scroll_x / TILE_SIZE) - 2
	var grid_x_max: int = floori((scroll_x + view_size.x) / TILE_SIZE) + 2
	var grid_y_min: int = floori(scroll_y / TILE_SIZE) - 2
	var grid_y_max: int = floori((scroll_y + view_size.y) / TILE_SIZE) + 2

	for grid_x in range(grid_x_min, grid_x_max + 1):
		for grid_y in range(grid_y_min, grid_y_max + 1):
			if not generated_cells.has(Vector2i(grid_x, grid_y)):
				_generate_or_show_tile(grid_x, grid_y)

func _generate_or_show_tile(grid_x: int, grid_y: int) -> void:
	var cell := Vector2i(grid_x, grid_y)
	
	# Generate tile type based on noise
	var tile_type = _tile_type_for_grid_cell(grid_x, grid_y)
	if tile_type == null:
		generated_cells[cell] = true
		return
	
	# Acquire or create tile
	var tile := _acquire_tile()
	tile.configure(tile_type, _cell_angle(cell), _cell_texture_index(cell), cell, TILE_SIZE)
	add_child(tile)
	
	active_tiles[cell] = tile
	generated_cells[cell] = true

func _tile_type_for_grid_cell(grid_x: int, grid_y: int) -> Variant:
	var cell := Vector2i(grid_x, grid_y)
	
	# Use a stable surface for the background
	var surface_y: int = roundi(SURFACE_BASE + surface_noise.get_noise_1d(grid_x) * SURFACE_AMPLITUDE)
	
	if grid_y < surface_y:
		return null # air
	
	var bulk := noise.get_noise_2d(grid_x, grid_y)
	var cave := _cave_at(cell)
	var cave_penalty: float = maxf(cave - CAVE_SPARSITY, 0.0) * CAVE_STRENGTH
	var cave_gate: float = clampf((CAVE_GATE_HARD - bulk) / (CAVE_GATE_HARD - CAVE_GATE_SOFT), 0.0, 1.0)
	var combined: float = bulk - cave_penalty * cave_gate
	
	if combined < AIR_THRESHOLD:
		return null
	
	var depth: int = grid_y - surface_y
	var is_heavy: bool = combined >= HEAVY_THRESHOLD
	
	if depth == 0:
		return Tile.Type.GRASS
	if depth <= DIRT_DEPTH:
		return Tile.Type.DIRT
	
	# Stone tier logic (simplified)
	var height_ratio: float = clampf(1.0 - float(grid_y) / 500.0, 0.0, 1.0)
	var explosive_threshold: float = 0.49 - height_ratio * 0.10
	if explosive_noise.get_noise_2d(grid_x, grid_y) > explosive_threshold:
		return Tile.Type.EXPLOSIVE
	
	var below_dirt: int = depth - DIRT_DEPTH - 1
	var stone_num: int = clampi(below_dirt / STONE_TIER_HEIGHT + 1, 1, 5)
	
	if is_heavy and stone_num < 5:
		var emerald_threshold: float = 0.48 - height_ratio * 0.28
		if emerald_noise.get_noise_2d(grid_x, grid_y) > emerald_threshold:
			return Tile.Type.EMERALD
	
	var diamond_threshold: float = 0.45 - height_ratio * 0.15
	if is_heavy:
		diamond_threshold -= 0.12
	if diamond_noise.get_noise_2d(grid_x, grid_y) > diamond_threshold:
		return Tile.Type.DIAMOND
	
	var gold_threshold: float = 0.35 + height_ratio * 0.10
	if gold_noise.get_noise_2d(grid_x, grid_y) > gold_threshold:
		return Tile.Type.GOLD
	
	if is_heavy and stone_num > 1:
		stone_num -= 1
	
	return STONE_TYPES[stone_num - 1]

func _cave_at(cell: Vector2i) -> float:
	var m := cave_noise.get_noise_2d(cell.x, cell.y)
	m = maxf(m, cave_noise.get_noise_2d(cell.x - 1, cell.y))
	m = maxf(m, cave_noise.get_noise_2d(cell.x + 1, cell.y))
	m = maxf(m, cave_noise.get_noise_2d(cell.x, cell.y - 1))
	m = maxf(m, cave_noise.get_noise_2d(cell.x, cell.y + 1))
	return m

func _cell_angle(cell: Vector2i) -> float:
	var h: int = hash(Vector2i(cell.x, cell.y)) ^ world_seed
	return (absi(h) % 10000) / 10000.0 * TAU

func _cell_texture_index(cell: Vector2i) -> int:
	var h: int = hash(Vector2i(cell.x, cell.y)) ^ world_seed ^ 0xA5A5A5A5
	return absi(h) % 6

func _grid_to_pixel(grid_cell: Vector2i) -> Vector2:
	# Convert grid coordinates to pixel position, accounting for scroll
	var pixel_x: float = float(grid_cell.x) * TILE_SIZE - scroll_x
	var pixel_y: float = float(grid_cell.y) * TILE_SIZE - scroll_y
	return Vector2(pixel_x, pixel_y)

func _update_tile_positions() -> void:
	for grid_cell in active_tiles.keys():
		var tile: Tile = active_tiles[grid_cell]
		var pixel_pos: Vector2 = _grid_to_pixel(grid_cell)
		# Center the tile on its grid position
		tile.position = pixel_pos + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

# Object pooling
func _acquire_tile() -> Tile:
	if tile_pool.is_empty():
		return tile_scene.instantiate() as Tile
	return tile_pool.pop_back()

func _release_tile(tile: Tile) -> void:
	remove_child(tile)
	tile_pool.append(tile)

func _apply_resolution_zoom() -> void:
	var w: float = get_viewport_rect().size.x
	var factor: float = maxf(w / REFERENCE_WIDTH, 0.1)
	var z := Vector2(BASE_ZOOM * factor, BASE_ZOOM * factor)
	if has_node("TheGuy/Camera2D"):
		get_node("TheGuy/Camera2D").zoom = z
