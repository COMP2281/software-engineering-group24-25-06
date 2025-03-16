extends Control

@onready var player_health = $Playerhealth
@onready var enemy_health = $Enemyhealth
@onready var player_health_label = $Playerhealth/Healthlabel
@onready var enemy_health_label = $Enemyhealth/Healthlabel

func _ready():
	style_health_bar()
	update_health_displays()
	
func set_enemy(enemy_resource: EnemyResource):
	enemy_health.max_value = enemy_resource.health
	enemy_health.value = enemy_health.max_value
	update_health_displays()

func style_health_bar():
	player_health.max_value = 100
	player_health.value = 100
	
	# NOTE: using godot's themes now instead

func update_health_displays():
	if player_health_label:
		player_health_label.text = str(player_health.value) + "/" + str(player_health.max_value)
	if enemy_health_label:
		enemy_health_label.text = str(enemy_health.value) + "/" + str(enemy_health.max_value)
	
func update_player_health(new_value:int):
	player_health.value = new_value
	update_health_displays()

func update_enemy_health(new_value:int):
	enemy_health.value = new_value
	update_health_displays()
	
	
