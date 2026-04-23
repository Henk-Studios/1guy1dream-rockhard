extends Node

signal credits
var creditsreached = false

var jetpackspeed = 700


var money = 0
var damage = 1
var width := 0.1 # cone half-angle (radians)
var particles_per_second := 3
var particle_speed := 300.0

# Explosive-bullet upgrades. 0 = no explosions.
var bullet_explosive_chance_level: int = 0  # likelihood — 1% per level
var bullet_explosive_size_level: int = 0    # blast radius bonus
