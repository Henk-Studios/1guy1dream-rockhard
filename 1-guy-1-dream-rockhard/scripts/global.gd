extends Node

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
