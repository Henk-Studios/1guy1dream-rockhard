extends StaticBody2D
class_name Tile

enum Type {GRASS, DIRT, STONE_1, STONE_2, STONE_3, STONE_4, STONE_5, GOLD, DIAMOND, EMERALD, EXPLOSIVE}

const TILE_SIZE := 16
const SPRITE_SCALE := 0.01

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
	Type.STONE_2: 50,
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

@onready var _shape_node: CollisionShape2D = $CollisionShape2D
@onready var _sprite_node: Sprite2D = $Sprite2D

var tile_type: Type = Type.STONE_3
var sprite_angle: float = 0.0
var texture_index: int = 0
var cell: Vector2i = Vector2i.ZERO
var context_tile_size: int = TILE_SIZE

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

func _apply_visual() -> void:
	if tile_type == Type.GRASS or tile_type == Type.DIRT:
		_sprite_node.texture = ROUNDISH_STONE
	else:
		_sprite_node.texture = STONE_TEXTURES[texture_index % STONE_TEXTURES.size()]
	_sprite_node.scale = Vector2(float(context_tile_size) / 400, float(context_tile_size) / 400)
	_sprite_node.modulate = COLORS[tile_type]
	_sprite_node.rotation = sprite_angle

func animate_hit(hp_lost: int) -> void:
	# reduce size more and more based on damage taken, with a minimum size limit
	var damage_ratio: float = clampf(float(hp_lost) / float(HP[tile_type]), 0.0, 1.0)
	var scale_factor: float = 1.0 - damage_ratio * 0.5
	_sprite_node.scale = Vector2(float(context_tile_size) / 400, float(context_tile_size) / 400) * scale_factor
	play_sfx()
	# shake()
	Manager.scene.current_scene.break_particle_pool.spawn_particles_at(global_position, 1, COLORS[tile_type])


func animate_break() -> void:
	play_sfx()
	Manager.scene.current_scene.break_particle_pool.spawn_particles_at(global_position, 3, COLORS[tile_type])
	return

func play_sfx() -> void:
	match tile_type:
		Type.GRASS, Type.DIRT:
			Manager.audio.play_dirt_sfx()
		Type.STONE_1:
			Manager.audio.play_rock_sfx(0.4)
		Type.STONE_2:
			Manager.audio.play_rock_sfx(0.55)
		Type.STONE_3:
			Manager.audio.play_rock_sfx(0.7)
		Type.STONE_4:
			Manager.audio.play_rock_sfx(0.85)
		Type.STONE_5:
			Manager.audio.play_rock_sfx(1.0)
		Type.GOLD:
			Manager.audio.play_bling_sfx(1.0)
		Type.DIAMOND:
			Manager.audio.play_bling_sfx(0.8)
		Type.EMERALD:
			Manager.audio.play_bling_sfx(0.6)

# func shake() -> void:
# 	var original_position = global_position
# 	var shake_amount = 1.5
# 	var tween = create_tween()
# 	tween.set_trans(Tween.TRANS_SINE)
# 	tween.set_ease(Tween.EASE_IN_OUT)
	
# 	for i in range(4):
# 		var random_offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
# 		tween.tween_property(_sprite_node, "global_position", original_position + random_offset, 0.025)
# 	tween.tween_callback(func(): global_position = original_position)
# 	return
