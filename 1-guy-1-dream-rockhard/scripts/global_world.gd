extends Node

var main: LocalWorld
var terrain: Terrain
var the_guy: TheGuy
var camera: Camera2D
var credits: Credits
var lava: Lava
var break_particle_pool: ParticlePool
var explode_particle_pool: ParticlePool
var bullet_pool: BulletPool

func setup(p_main: LocalWorld, p_terrain: Terrain, p_the_guy: TheGuy, p_camera: Camera2D, p_credits: Credits, p_lava: Lava, p_break_particle_pool: ParticlePool, p_explode_particle_pool: ParticlePool, p_bullet_pool: BulletPool) -> void:
	main = p_main
	terrain = p_terrain
	the_guy = p_the_guy
	camera = p_camera
	credits = p_credits
	lava = p_lava
	break_particle_pool = p_break_particle_pool
	explode_particle_pool = p_explode_particle_pool
	bullet_pool = p_bullet_pool
