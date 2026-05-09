extends Node2D
class_name LocalWorld

@export var terrain: Terrain
@export var the_guy: TheGuy
@export var camera: Camera2D
@export var credits: Credits
@export var lava: Lava
@export var bullet_pool: BulletPool
@export var break_particle_pool: ParticlePool
@export var explode_particle_pool: ParticlePool
var time_frozen: bool = true
var time_elapsed: float = 0.0


var shop_open := false
var jetpackspeed = 700
signal money_changed(money)
# enable dev mode by clicking the top right corner 3 times in the main menu (??? message will appear when toggled)
var dev_mode := false
var debugging := true
var money: int:
	set(value):
		money = value
		money_changed.emit(money)
var damage = 100
var piercing = 0
var ricochet = 0
var width := 0.1 # cone half-angle (radians)
var particles_per_second := 5
var particle_speed := 300.0
var vision := 0.3

# Explosive-bullet upgrades. 0 = no explosions.
var bullet_explosive_chance_level: int = 0 # likelihood — 1% per level
var bullet_explosive_size_level: int = 0 # blast radius bonus

func _physics_process(delta: float) -> void:
	if not time_frozen:
		time_elapsed += delta

func setup(params) -> void:
	if debugging:
		dev_mode = true
	time_frozen = true

	World.setup(self , terrain, the_guy, camera, credits, lava, break_particle_pool, explode_particle_pool, bullet_pool)
	terrain.setup(params)
	camera.setup()
	var shop = get_node("WorldUI/CenterControl/RadialMenu") as RadialMenu
	shop.setup()
	Manager.scene.finish_loading()
	Manager.message.info(" Use [color=lime]A[/color], [color=lime]D[/color], or [color=lime]<-, ->[/color], (keyboard) or [color=lime]RT[/color], [color=lime]LT[/color] (gamepad) to [color=yellow]move", 20)
	Manager.message.info(" Use [color=lime]Mouse[/color] or [color=lime]Right Stick [/color] (gamepad) to [color=magenta]aim and shoot", 20)
	Manager.message.info(" Press [color=lime]S[/color] (keyboard) or [color=lime]Y + Left Stick[/color] (gamepad) to open the [color=cyan]upgrade menu", 20)
	Manager.message.info(" Press [color=lime]ESC[/color] (keyboard) or [color=lime]Start[/color] (gamepad) to [color=orange]pause", 20)
	Manager.message.info(" [color=magenta][wave amp=10.0]Now be the 1guy and achieve your 1dream!!![/wave][/color]", 20)
	Manager.audio.fade_out_music()

	await get_node("WorldUI/Countdown").countdown()
	the_guy.enable()
	time_frozen = false
	Manager.audio.play_main_music()