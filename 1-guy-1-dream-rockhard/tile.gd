extends StaticBody2D
class_name Tile

enum Type { GRASS, DIRT, STONE_1, STONE_2, STONE_3, STONE_4, STONE_5 }

const TILE_SIZE := 16
const ATLAS := preload("res://tiles.png")

# Atlas columns in tiles.png (16px each, same row).
const REGIONS := {
	Type.GRASS: Rect2(0, 0, 16, 16),
	Type.DIRT: Rect2(16, 0, 16, 16),
	Type.STONE_1: Rect2(32, 0, 16, 16),
	Type.STONE_2: Rect2(48, 0, 16, 16),
	Type.STONE_3: Rect2(64, 0, 16, 16),
	Type.STONE_4: Rect2(80, 0, 16, 16),
	Type.STONE_5: Rect2(96, 0, 16, 16),
}

var tile_type: Type = Type.STONE_3
var sprite_angle: float = 0.0

func configure(type: Type, angle: float) -> void:
	tile_type = type
	sprite_angle = angle

func _ready() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	shape_node.shape = shape
	add_child(shape_node)

	var sprite := Sprite2D.new()
	sprite.texture = ATLAS
	sprite.region_enabled = true
	sprite.region_rect = REGIONS[tile_type]
	sprite.rotation = sprite_angle
	add_child(sprite)
