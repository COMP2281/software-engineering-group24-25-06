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
	player_health.custom_minimum_size = Vector2(120, 30)
	player_health.position = Vector2(50, get_viewport().size.y - 100)
	
	var player_style = StyleBoxFlat.new()
	player_style.bg_color = Color(0, 0, 0, 1)  # Black background
	player_style.border_color = Color(1, 1, 1)  # White border
	player_style.skew = Vector2(-0.2, 0)  # Persona 5 slant
	player_style.corner_radius_top_left = 8
	player_style.corner_radius_bottom_right = 8
	
	var player_bg_style = StyleBoxFlat.new()
	player_bg_style.bg_color = Color(0.2, 0.2, 0.2, 1)  # Dark gray background
	player_bg_style.skew = Vector2(-0.2, 0)
	player_bg_style.corner_radius_top_left = 8
	player_bg_style.corner_radius_bottom_right = 8
	
	player_health.add_theme_stylebox_override("fill", player_style)
	player_health.add_theme_stylebox_override("background", player_bg_style)
	
	player_health_label.add_theme_color_override("font_color", Color.WHITE)
	player_health_label.position = Vector2(30, -25)  # Position above health bar
 
	enemy_health.custom_minimum_size = Vector2(120, 30)
	enemy_health.position = Vector2(get_viewport().size.x - 170, get_viewport().size.y - 100)
	
	var enemy_style = player_style.duplicate()
	var enemy_bg_style = player_bg_style.duplicate()
	
	enemy_health.add_theme_stylebox_override("fill", enemy_style)
	enemy_health.add_theme_stylebox_override("background", enemy_bg_style)
	
	enemy_health_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_health_label.position = Vector2(30, -25)

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
	
	
