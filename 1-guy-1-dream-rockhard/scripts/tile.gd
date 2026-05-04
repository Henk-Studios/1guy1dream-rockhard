extends StaticBody2D
class_name Tile

enum Type {GRASS, DIRT, STONE_1, STONE_2, STONE_3, STONE_4, STONE_5, UNBREAKABLE, GOLD, DIAMOND, EMERALD, EXPLOSIVE}

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
	Type.STONE_1: Color(0.16, 0.16, 0.18),
	Type.STONE_2: Color(0.28, 0.28, 0.30),
	Type.STONE_3: Color(0.42, 0.42, 0.44),
	Type.STONE_4: Color(0.58, 0.58, 0.60),
	Type.STONE_5: Color(0.78, 0.78, 0.80),
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
	Type.STONE_1: 50000,
	Type.STONE_2: 5000,
	Type.STONE_3: 2000,
	Type.STONE_4: 600,
	Type.STONE_5: 200,
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
	Type.STONE_1: 10,
	Type.STONE_2: 8,
	Type.STONE_3: 5,
	Type.STONE_4: 2,
	Type.STONE_5: 1,
	Type.GOLD: 10,
	Type.DIAMOND: 25,
	Type.EMERALD: 500,
	Type.EXPLOSIVE: 0,
	Type.UNBREAKABLE: 0,
}

const STRING_NAMES := {
	Type.GRASS: "Grass",
	Type.DIRT: "Dirt",
	Type.STONE_1: "Stone 1",
	Type.STONE_2: "Stone 2",
	Type.STONE_3: "Stone 3",
	Type.STONE_4: "Stone 4",
	Type.STONE_5: "Stone 5",
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
	name = "%s_%d,%d" % [STRING_NAMES[tile_type], cell.x, cell.y]
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
	_sprite_node.scale = Vector2(float(context_tile_size) / 100, float(context_tile_size) / 100)
	_sprite_node.self_modulate = COLORS[tile_type]
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
	var crack_color = COLORS[tile_type]
	crack_color.a = randf_range(0.5, 1.0)
	if (randi() % 20 == 0 and not (tile_type == Type.GRASS or tile_type == Type.DIRT)) or tile_type == Type.EXPLOSIVE or tile_type == Type.GOLD or tile_type == Type.DIAMOND or tile_type == Type.EMERALD:
		_cracks_sprite_node.texture = crack_textures[4]
		crack_color = crack_color.lightened(randf_range(0.0, 1.0))
	else:
		crack_color = crack_color.darkened(randf_range(0.0, 1.0))
	_cracks_sprite_node.self_modulate = crack_color

func animate_hit(hp_lost: int) -> void:
	# reduce size more and more based on damage taken, with a minimum size limit
	var damage_ratio: float = clampf(float(hp_lost) / float(HP[tile_type]), 0.0, 1.0)
	var scale_factor: float = 1.0 - damage_ratio * 0.5
	_sprite_node.scale = Vector2(float(context_tile_size) / 100, float(context_tile_size) / 100) * scale_factor
	play_sfx()
	# shake()
	World.break_particle_pool.spawn_particles_at(global_position, 1, COLORS[tile_type])


func animate_break() -> void:
	play_sfx()
	World.break_particle_pool.spawn_particles_at(global_position, 3, COLORS[tile_type])
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
