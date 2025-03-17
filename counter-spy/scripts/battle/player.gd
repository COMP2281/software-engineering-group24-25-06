## TODO: both of these scripts should be purely visual stuff basically
##	and instead we handle most of everything in battle.gd
class_name PlayerBattle extends CharacterBody3D

@export var max_health: float = 100.0

signal health_change(health_change: float)

func _ready():
	position = Vector3(-3, 1, 0)
	
	health_change.connect(on_health_change)
	
# TODO: functionality of any visual changes you might need goes here e.g.
#	- player flashes red
#   - player takes some visual knockback (might be hard to do)
func on_health_change(health_change: float):
	print("Visual stuff here!")
