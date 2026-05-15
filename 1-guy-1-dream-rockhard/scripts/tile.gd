extends StaticBody2D
class_name Tile

enum Type {GRASS, DIRT, UNBREAKABLE, GOLD, DIAMOND, EMERALD, EXPLOSIVE}

const TILE_SIZE := 16

const STONE_TEXTURES: Array[Texture2D] = [
	preload("res://textures/ugly stone.png"),
	preload("res://textures/ragged stone.png"),
	preload("res://textures/normie stone.png"),
	preload("res://textures/badly skinned potato stone.png"),
	preload("res://textures/roundish stone.png"),
	preload("res://textures/sharp stone.png"),
]
const ROUNDISH_STONE: Texture2D = preload("res://textures/roundish stone.png")

const COLORS := {
	Type.GRASS: Color(0.35, 0.58, 0.24),
	Type.DIRT: Color(0.44, 0.29, 0.16),
	Type.UNBREAKABLE: Color(0.2, 0.1, 0.1),
	Type.GOLD: Color(1.0, 0.85, 0.2),
	Type.DIAMOND: Color(0.45, 0.75, 1.0),
	Type.EMERALD: Color(0.3, 0.95, 0.5),
	Type.EXPLOSIVE: Color(0.9, 0.15, 0.1),
}

# Durability per tile type. Stone 1 is hardest; dirt sits below stone 5; grass is softest.
const HP := {
	Type.GRASS: 100,
	Type.DIRT: 100,
	Type.UNBREAKABLE: 9999,
	Type.GOLD: 500,
	Type.DIAMOND: 1000,
	Type.EMERALD: 3000,
	Type.EXPLOSIVE: 1,
}

# Coin reward when a tile is fully broken.
const COIN_VALUES := {
	Type.GRASS: 0,
	Type.DIRT: 0,
	Type.UNBREAKABLE: 0,
	Type.GOLD: 10,
	Type.DIAMOND: 25,
	Type.EMERALD: 500,
	Type.EXPLOSIVE: 0,
}

const STRING_NAMES := {
	Type.GRASS: "Grass",
	Type.DIRT: "Dirt",
	Type.UNBREAKABLE: "Unbreakable",
	Type.GOLD: "Gold",
	Type.DIAMOND: "Diamond",
	Type.EMERALD: "Emerald",
	Type.EXPLOSIVE: "Explosive",
}

@onready var _shape_node: CollisionShape2D = $CollisionShape2D
@onready var _sprite_node: Sprite2D = $Sprite2D
@onready var _cracks_sprite_node: Sprite2D = $Sprite2D/GrainSprite2D
@export var crack_textures: Array[Texture2D]
var crack_texture_probabilities: Array[float] = [0.0, 0.0, 0.2, 0.6, 0.2]

var tile_type: Type
var sprite_angle: float = 0.0
var texture_index: int = 0
var cell: Vector2i = Vector2i.ZERO
var context_tile_size: int = TILE_SIZE

static func is_stone(tt: int) -> bool:
	return tt >= Type.size()

static func stone_index(tt: int) -> int:
	return tt - Type.size()

static func stone(index: int) -> int:
	return Type.size() + index

func configure(type: Type, angle: float, tex_idx: int, cell_: Vector2i, tile_size: int = TILE_SIZE) -> void:
	tile_type = type
	sprite_angle = angle
	texture_index = tex_idx
	cell = cell_
	context_tile_size = tile_size
	if _sprite_node:
		_apply_visual()

func _ready() -> void:
	_shape_node.shape.size = Vector2(context_tile_size, context_tile_size)
	_apply_visual()

func get_color() -> Color:
	if is_stone(tile_type):
		var c = 1 - 0.14 * (stone_index(tile_type) % 7)
		return Color(c, c, c)
	else:
		return COLORS[tile_type]

static func get_hp(tt: int) -> int:
	if is_stone(tt):
		return 200 * (3 ** (stone_index(tt) - 1))
	else: return HP[tt]

static func get_value(tt: int) -> int:
	if is_stone(tt):
		return stone_index(tt) ** 2
	else:
		return COIN_VALUES[tt]

func _apply_visual() -> void:
	if tile_type == Type.GRASS or tile_type == Type.DIRT:
		_sprite_node.texture = ROUNDISH_STONE
	else:
		_sprite_node.texture = STONE_TEXTURES[texture_index % STONE_TEXTURES.size()]
	_sprite_node.scale = Vector2(float(context_tile_size) / 100, float(context_tile_size) / 100)
	_sprite_node.self_modulate = get_color()
	_sprite_node.rotation = sprite_angle
	# Randomly select a crack texture based on defined probabilities
	var rand = randf()
	var cumulative_probability = 0.0
	var selected_texture: Texture2D = null
	for i in range(crack_textures.size()):
		cumulative_probability += crack_texture_probabilities[i]
		if rand < cumulative_probability:
			selected_texture = crack_textures[i]
			break
	if not selected_texture:
		selected_texture = crack_textures[crack_textures.size() - 1]
	_cracks_sprite_node.texture = selected_texture
	# random scale
	_cracks_sprite_node.scale = Vector2.ONE * randf_range(0.5, 1.5)
	_cracks_sprite_node.rotation = randf_range(0, PI * 2)
	
	var crack_color: Color = get_color()
	crack_color.a = randf_range(0.5, 1.0)
	if (randi() % 20 == 0 and not (tile_type == Type.GRASS or tile_type == Type.DIRT)) or tile_type == Type.EXPLOSIVE or tile_type == Type.GOLD or tile_type == Type.DIAMOND or tile_type == Type.EMERALD:
		_cracks_sprite_node.texture = crack_textures[4]
		crack_color = crack_color.lightened(randf_range(0.0, 1.0))
	else:
		crack_color = crack_color.darkened(randf_range(0.0, 1.0))
	_cracks_sprite_node.self_modulate = crack_color

func animate_hit(hp_lost: int) -> void:
	# reduce size more and more based on damage taken, with a minimum size limit
	var damage_ratio: float = clampf(float(hp_lost) / float(get_hp(tile_type)), 0.0, 1.0)
	var scale_factor: float = 1.0 - damage_ratio * 0.5
	_sprite_node.scale = Vector2(float(context_tile_size) / 100, float(context_tile_size) / 100) * scale_factor
	play_sfx()
	World.break_particle_pool.spawn_particles_at(global_position, 1, get_color())


func animate_break() -> void:
	play_sfx()
	World.break_particle_pool.spawn_particles_at(global_position, 1, get_color())
	return

func play_sfx() -> void:
	if is_stone(tile_type):
		Manager.audio.play_rock_sfx(1.0 - 0.1 * (stone_index(tile_type) % 6))
	match tile_type:
		Type.GRASS, Type.DIRT:
			Manager.audio.play_dirt_sfx()
		Type.GOLD:
			Manager.audio.play_bling_sfx(1.0)
		Type.DIAMOND:
			Manager.audio.play_bling_sfx(0.8)
		Type.EMERALD:
			Manager.audio.play_bling_sfx(0.6)
