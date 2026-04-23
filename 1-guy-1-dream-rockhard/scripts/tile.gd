extends StaticBody2D
class_name Tile

enum Type { GRASS, DIRT, STONE_1, STONE_2, STONE_3, STONE_4, STONE_5 }

const TILE_SIZE := 16
const SPRITE_SCALE := 2.2  # rendered sprite size = TILE_SIZE * SPRITE_SCALE (creates overlap bleed)

const STONE_TEXTURES: Array[Texture2D] = [
	preload("res://textures/ugly stone.png"),
	preload("res://textures/ragged stone.png"),
	preload("res://textures/normie stone.png"),
	preload("res://textures/badly skinned potato stone.png"),
	preload("res://textures/roundish stone.png"),
	preload("res://textures/sharp stone.png"),
]
const ROUNDISH_STONE: Texture2D = preload("res://textures/roundish stone.png")

# Tint applied to the albedo texture per tile type.
const COLORS := {
	Type.GRASS: Color(0.35, 0.58, 0.24),
	Type.DIRT: Color(0.44, 0.29, 0.16),
	Type.STONE_1: Color(0.16, 0.16, 0.18),
	Type.STONE_2: Color(0.28, 0.28, 0.30),
	Type.STONE_3: Color(0.42, 0.42, 0.44),
	Type.STONE_4: Color(0.58, 0.58, 0.60),
	Type.STONE_5: Color(0.78, 0.78, 0.80),
}

var tile_type: Type = Type.STONE_3
var sprite_angle: float = 0.0
var texture_index: int = 0

func configure(type: Type, angle: float, tex_idx: int) -> void:
	tile_type = type
	sprite_angle = angle
	texture_index = tex_idx

func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	shape_node.shape = shape
	add_child(shape_node)

	var sprite := Sprite2D.new()
	if tile_type == Type.GRASS or tile_type == Type.DIRT:
		sprite.texture = ROUNDISH_STONE
	else:
		sprite.texture = STONE_TEXTURES[texture_index % STONE_TEXTURES.size()]
	sprite.modulate = COLORS[tile_type]
	sprite.rotation = sprite_angle
	var tex_size := sprite.texture.get_size()
	var target: float = TILE_SIZE * SPRITE_SCALE
	sprite.scale = Vector2(target / tex_size.x, target / tex_size.y)
	add_child(sprite)
