extends Node2D

@export var terrain: Terrain
@export var the_guy: Node2D
@export var camera: Camera2D
@export var credits: Credits
@export var lava: Lava
@export var bullet_pool: BulletPool
@export var break_particle_pool: ParticlePool
@export var explode_particle_pool: ParticlePool

var time_frozen: bool = false
var time_elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	if not time_frozen:
		time_elapsed += delta

func setup(params) -> void:
	if Global.debugging:
		Global.dev_mode = true

	World.setup(self , terrain, the_guy, camera, credits, lava, break_particle_pool, explode_particle_pool, bullet_pool)
	terrain.setup(params)
	camera.setup()
	Manager.scene.finish_loading()
	Manager.message.info(" Use [color=lime]A[/color], [color=lime]D[/color], or [color=lime]<-, ->[/color], (keyboard) or [color=lime]RT[/color], [color=lime]LT[/color] (gamepad) to [color=yellow]move", 20)
	Manager.message.info(" Use [color=lime]Mouse[/color] or [color=lime]Right Stick [/color] (gamepad) to [color=magenta]aim and shoot", 20)
	Manager.message.info(" Press [color=lime]E[/color] (keyboard) or [color=lime]Y + Left Stick[/color] (gamepad) to open the [color=cyan]upgrade menu", 20)
	Manager.message.info(" Press [color=lime]ESC[/color] (keyboard) or [color=lime]Start[/color] (gamepad) to [color=orange]pause", 20)
	Manager.message.info(" [color=magenta][wave amp=10.0]Now be the 1guy and achieve your 1dream!!![/wave][/color]", 20)
