extends Node3D

@onready var player = $player
@onready var enemy = $enemy
@onready var player_health = $CanvasLayer/UI/Playerhealth
@onready var enemy_health = $CanvasLayer/UI/Enemyhealth

var current_turn = "player"
var success_percentage = 75  

signal success_rate_change(percentage)

func _ready():
	
	await get_tree().process_frame
	if player and enemy:
		player.health_change.connect(_on_player_health_changed)
		enemy.health_change.connect(_on_enemy_health_changed)
	setup_health_bars()
	update_ui()

func setup_health_bars():
	player_health.max_value = player.max_health
	player_health.value = player.health
	
	enemy_health.max_value = enemy.max_health
	enemy_health.value = enemy.health
	
	var screen_width = get_viewport().size.x
	enemy_health.position.x = screen_width - 220

func update_ui():
	player_health.value = player.health
	enemy_health.value = enemy.health

func _on_player_health_changed(new_health):
	player_health.value = new_health

func _on_enemy_health_changed(new_health):
	enemy_health.value = new_health

# Connect this to question system later
func on_question_answered(correct):
	if correct:
		success_percentage += 10
		success_percentage = min(success_percentage, 100)
	else:
		success_percentage -= 15
		success_percentage = max(success_percentage, 20)
	success_rate_change.emit(success_percentage)
