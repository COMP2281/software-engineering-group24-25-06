extends Node3D

@onready var player = $player
@onready var enemy = $enemy
@onready var player_health = $CanvasLayer/UI/Playerhealth
@onready var enemy_health = $CanvasLayer/UI/Enemyhealth
@onready var battle_menu = $CanvasLayer/UI/Battlemenu
@onready var question_panel = $CanvasLayer/UI/Questionpanel
@onready var question_manager = $Questionmanager
@onready var ui = $CanvasLayer/UI


var player_max_health = 80
var enemy_max_health = 80
var player_defense = false
var current_turn = "player"
var current_credential = "Getting Started with Artificial Intelligence"


func _ready():
	
	setup_battle()
	battle_menu.connect("option_selected", _on_option_selected)
	question_panel.connect("answer_selected", _on_answer_selected)
	start_turn()
	await get_tree().process_frame
	if player and enemy:
		player.health_change.connect(_on_player_health_changed)
		enemy.health_change.connect(_on_enemy_health_changed)
	player_health.max_value = player_max_health
	player_health.value = player_max_health
	enemy_health.max_value = enemy_max_health
	enemy_health.value = enemy_max_health

func setup_battle():
	question_panel.hide()
	battle_menu.hide_menu()
	
func start_turn():
	print("Starting turn...")
	var question = question_manager.get_question(current_credential)
	if question:
		print("Question found:", question.question)
		question_panel.show_question(question)
	else:
		print("No question found!")
func _on_answer_selected(answer):
	var correct = question_manager.check_answer(answer)
	if correct:
		battle_menu.show_menu()
	else:
		start_enemy_turn()

func _on_option_selected(option):
	match option:
		"ATTACK":
			execute_attack()
		"GUARD":
			execute_guard()
		"ITEM":
			show_items()
		"WEAKNESS":
			reveal_weakness()
			

func execute_attack():
	var damage = 15
	apply_damage_to_enemy(damage)
	battle_menu.hide_menu()
	start_enemy_turn()
	
func execute_guard():
	player_defense = true
	battle_menu.hide_menu()
	start_enemy_turn()
	
func show_items():
	#ITEM LOGIC
	battle_menu.hide_menu()
	start_enemy_turn()
	
func reveal_weakness():
	#DISPLAY WEAKNESS
	battle_menu.hide_menu()
	start_enemy_turn()

func start_enemy_turn():
	await get_tree().create_timer(1.0).timeout
	execute_enemy_attack()
	
func execute_enemy_attack():
	var enemy_damage = 10
	
	if player_defense:
		enemy_damage = enemy_damage / 2
		player_defense = false
		
	apply_damage_to_player(enemy_damage)
	await get_tree().create_timer(1.0).timeout
	start_turn()
	
func apply_damage_to_player(damage):
	var new_health = max(0, player_health.value - damage)
	_on_player_health_changed(new_health)
	
	if new_health <= 0:
		game_over(false)

func apply_damage_to_enemy(damage):
	var new_health = max(0, enemy_health.value - damage)
	_on_enemy_health_changed(new_health)
	
	if new_health <= 0:
		game_over(true)
		

func game_over(player_won: bool):
	battle_menu.hide_menu()
	question_panel.hide()
	
	var game_over_panel = $CanvasLayer/UI/Gameoverpanel
	var result_label = $CanvasLayer/UI/Gameoverpanel/Resultlabel
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.9)
	panel_style.border_color = Color(1, 0, 0)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_bottom_right = 15
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	game_over_panel.custom_minimum_size = Vector2(400, 200)
	game_over_panel.position = Vector2(
		(get_viewport().size.x - game_over_panel.custom_minimum_size.x) / 2,
		(get_viewport().size.y - game_over_panel.custom_minimum_size.y) / 2
	)
	if player_won:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	else:
		result_label.text = "DEFEAT!"
		result_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
	result_label.add_theme_font_size_override("font_size", 32)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER   
	game_over_panel.show() 
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func _on_player_health_changed(new_health):
	player_health.value = new_health
	if $CanvasLayer/UI/Playerhealth/Healthlabel:
		$CanvasLayer/UI/Playerhealth/Healthlabel.text = str(new_health) + "/" + str(player_max_health)
	
func _on_enemy_health_changed(new_health):
	enemy_health.value = new_health
	if $CanvasLayer/UI/Enemyhealth/Healthlabel:
		$CanvasLayer/UI/Enemyhealth/Healthlabel.text = str(new_health) + "/" + str(enemy_max_health)
