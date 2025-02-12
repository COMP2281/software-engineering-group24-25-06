class_name Encounter extends Node3D

var enemy:Enemy

var player_health = 100
var enemy_health

@onready var camera:Camera3D = $Camera3D
@onready var canvas:Control = $Control

signal encounter_done

func _ready() -> void:
	#enemy_health = enemy.health
	pass


func _on_button_pressed() -> void:
	encounter_done.emit()
