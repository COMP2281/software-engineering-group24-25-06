class_name EncounterNode extends Node3D

@onready var player: PlayerBattle = $player
@onready var enemy: EnemyBattle = $enemy
@onready var player_health = $CanvasLayer/UI/Playerhealth
@onready var enemy_health = $CanvasLayer/UI/Enemyhealth
@onready var battle_menu = $CanvasLayer/UI/Battlemenu
@onready var question_panel = $CanvasLayer/UI/Questionpanel
@onready var ui = $CanvasLayer/UI

var player_health_value: float = 0.0
var enemy_health_value: float = 0.0
var enemy_max_health: float = 0.0
# If the player is defending
var player_defense: bool = false
var current_turn: String = "player"

var enemy_being_fought: Enemy = null
var current_question: Question = null

func entered_from_mission(fighting_enemy: Enemy) -> void:
	enemy_being_fought = fighting_enemy
	enemy.enemy_resource = enemy_being_fought.enemy_resource
	enemy_max_health = enemy.enemy_resource.health
	enemy_health_value = enemy_max_health
	player_health_value = player.max_health
	
	ui.set_enemy(enemy.enemy_resource)

func prepare_enter() -> void:
	$CanvasLayer.show()
	$Camera3D.make_current()
	
	var game_over_panel = $CanvasLayer/UI/Gameoverpanel
	var result_label = $CanvasLayer/UI/Gameoverpanel/Resultlabel
	
	game_over_panel.hide()
	result_label.hide()
	
func prepare_exit() -> void:
	$CanvasLayer.hide()
	if $Camera3D.current:
		$Camera3D.clear_current(true)

func _ready() -> void:
	# Call it on the ready function, because we start on the mission scene
	setup_battle()
	battle_menu.connect("option_selected", _on_option_selected)
	question_panel.connect("answer_selected", _on_answer_selected)
	start_turn()
	# TODO: waiting for 1 process frame? not sure what its doing/if necessary
	await get_tree().process_frame
	
	if player and enemy:
		player.health_change.connect(_on_player_health_changed)
		enemy.health_change.connect(_on_enemy_health_changed)

func setup_battle() -> void:
	question_panel.hide()
	battle_menu.hide_menu()
	
func start_turn() -> void:
	print("Starting turn...")
	current_question = QuestionSelector.selectQuestion(QuestionSelector.TOPIC_AI, 0.5)
	if current_question:
		print("Question found:", current_question.text)
		question_panel.show_question(current_question)
	else:
		print("No question found!")

## Given an answer index 0-3, check if answer is correct
func _on_answer_selected(answer: int) -> void:
	var correct: bool = QuestionSelector.markQuestion(current_question, [answer])
	
	if correct:
		battle_menu.show_menu()
	else:
		start_enemy_turn()

# TODO(minor): should be enum
func _on_option_selected(option: String) -> void:
	match option:
		"ATTACK":
			execute_attack()
		"GUARD":
			execute_guard()
		"ITEM":
			show_items()
		"WEAKNESS":
			reveal_weakness()
			

func execute_attack() -> void:
	# TODO: should read out value from move settings/list
	var damage: float = 15.0
	apply_damage_to_enemy(damage)
	battle_menu.hide_menu()
	start_enemy_turn()
	
func execute_guard() -> void:
	player_defense = true
	battle_menu.hide_menu()
	start_enemy_turn()
	
func show_items() -> void:
	#ITEM LOGIC
	battle_menu.hide_menu()
	start_enemy_turn()
	
func reveal_weakness() -> void:
	#DISPLAY WEAKNESS
	battle_menu.hide_menu()
	start_enemy_turn()

func start_enemy_turn() -> void:
	await get_tree().create_timer(1.0).timeout
	execute_enemy_attack()
	
func execute_enemy_attack() -> void:
	var enemy_damage: float = 10.0
	
	if player_defense:
		enemy_damage = enemy_damage / 2
		player_defense = false
		
	apply_damage_to_player(enemy_damage)
	await get_tree().create_timer(1.0).timeout
	start_turn()
	
func apply_damage_to_player(damage: float) -> void:
	player_health_value -= damage
	player_health_value = clamp(player_health_value, 0.0, player.max_health)
	player.health_change.emit(player_health_value)
	
	if player_health_value == 0.0:
		game_over(false)

func apply_damage_to_enemy(damage: float) -> void:
	enemy_health_value -= damage
	enemy_health_value = clamp(enemy_health_value, 0.0, enemy_max_health)
	enemy.health_change.emit(enemy_health_value)
	
	if enemy_health_value <= 0:
		game_over(true)

func game_over(player_won: bool) -> void:
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

	if player_won:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	else:
		result_label.text = "DEFEAT!"
		result_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
	result_label.add_theme_font_size_override("font_size", 32)

	game_over_panel.show() 
	result_label.show()
	
	# TODO: Timer after victory (probably should be some animation that plays that we await?)
	await get_tree().create_timer(1.0).timeout
	
	SceneCoordinator.change_scene.emit(SceneType.Name.MISSION, { "enemy_defeated": enemy_being_fought })

func _on_player_health_changed(new_health: float):
	player_health.value = new_health
	if $CanvasLayer/UI/Playerhealth/Healthlabel:
		$CanvasLayer/UI/Playerhealth/Healthlabel.text = str(new_health) + "/" + str(player.max_health)
	
func _on_enemy_health_changed(new_health: float):
	enemy_health.value = new_health
	if $CanvasLayer/UI/Enemyhealth/Healthlabel:
		$CanvasLayer/UI/Enemyhealth/Healthlabel.text = str(new_health) + "/" + str(enemy_max_health)
