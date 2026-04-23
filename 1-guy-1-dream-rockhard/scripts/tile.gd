extends StaticBody2D
class_name Tile

enum Type { GRASS, DIRT, STONE_1, STONE_2, STONE_3, STONE_4, STONE_5, GOLD, DIAMOND, EMERALD, EXPLOSIVE }

const TILE_SIZE := 16
const SPRITE_SCALE := 2.5

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
	Type.STONE_1: Color(0.16, 0.16, 0.18),
	Type.STONE_2: Color(0.28, 0.28, 0.30),
	Type.STONE_3: Color(0.42, 0.42, 0.44),
	Type.STONE_4: Color(0.58, 0.58, 0.60),
	Type.STONE_5: Color(0.78, 0.78, 0.80),
	Type.GOLD: Color(1.0, 0.85, 0.2),
	Type.DIAMOND: Color(0.45, 0.75, 1.0),
	Type.EMERALD: Color(0.3, 0.95, 0.5),
	Type.EXPLOSIVE: Color(0.9, 0.15, 0.1),
}

# Durability per tile type. Stone 1 is hardest; dirt sits below stone 5; grass is softest.
const HP := {
	Type.GRASS: 1,
	Type.DIRT: 1,
	Type.STONE_1: 500,
	Type.STONE_2: 80,
	Type.STONE_3: 20,
	Type.STONE_4: 6,
	Type.STONE_5: 2,
	Type.GOLD: 5,
	Type.DIAMOND: 10,
	Type.EMERALD: 30,
	Type.EXPLOSIVE: 1,
}

# Coin reward when a tile is fully broken.
const COIN_VALUES := {
	Type.GRASS: 0,
	Type.DIRT: 0,
	Type.STONE_1: 10,
	Type.STONE_2: 8,
	Type.STONE_3: 5,
	Type.STONE_4: 2,
	Type.STONE_5: 1,
	Type.GOLD: 10,
	Type.DIAMOND: 25,
	Type.EMERALD: 500,
	Type.EXPLOSIVE: 0,
}

static var SHARED_SHAPE: RectangleShape2D = null

var tile_type: Type = Type.STONE_3
var sprite_angle: float = 0.0
var texture_index: int = 0
var cell: Vector2i = Vector2i.ZERO

var _sprite: Sprite2D = null

func configure(type: Type, angle: float, tex_idx: int, cell_: Vector2i) -> void:
	tile_type = type
	sprite_angle = angle
	texture_index = tex_idx
	cell = cell_
	if _sprite != null:
		_apply_visual()  # reuse path: update existing sprite immediately

func _ready() -> void:
	if _sprite != null:
		# Already built in a previous life (pooled then re-added). Just refresh.
		_apply_visual()
		return
	if SHARED_SHAPE == null:
		SHARED_SHAPE = RectangleShape2D.new()
		SHARED_SHAPE.size = Vector2(TILE_SIZE, TILE_SIZE)
	var shape_node := CollisionShape2D.new()
	shape_node.shape = SHARED_SHAPE
	add_child(shape_node)

	_sprite = Sprite2D.new()
	add_child(_sprite)
	_apply_visual()

func _apply_visual() -> void:
	if tile_type == Type.GRASS or tile_type == Type.DIRT:
		_sprite.texture = ROUNDISH_STONE
	else:
		_sprite.texture = STONE_TEXTURES[texture_index % STONE_TEXTURES.size()]
	_sprite.modulate = COLORS[tile_type]
	_sprite.rotation = sprite_angle
	var tex_size := _sprite.texture.get_size()
	var target: float = TILE_SIZE * SPRITE_SCALE
	_sprite.scale = Vector2(target / tex_size.x, target / tex_size.y)
