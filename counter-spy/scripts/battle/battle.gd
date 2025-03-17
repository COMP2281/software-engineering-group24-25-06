class_name EncounterNode extends Node3D

@onready var player: PlayerBattle = $player
@onready var enemy: EnemyBattle = $enemy
@onready var player_health = $CanvasLayer/UI/Playerhealth
@onready var enemy_health = $CanvasLayer/UI/Enemyhealth
@onready var battle_menu = $CanvasLayer/UI/Battlemenu
@onready var question_panel = $CanvasLayer/UI/Questionpanel
@onready var ui = $CanvasLayer/UI
@onready var timer_label = $CanvasLayer/UI/Timerlabel
@onready var lightning_tube : MeshInstance3D = $LightningTube

@export_color_no_alpha var lightning_player_color: Color
@export_color_no_alpha var lightning_enemy_color: Color

var player_health_value: float = 0.0
var enemy_health_value: float = 0.0
var enemy_max_health: float = 0.0
# If the player is defending
var player_defense: bool = false
var current_turn: String = "player"
var current_attack = null

var enemy_being_fought: Enemy = null
var current_question: Question = null
var question_time_left: float = INF

var attack_multiplier: float = 1.0
var attack_boost_turns_remaining: int = 0

var current_attack_option: Array[Move] = []

#ADDING TEMP ITEM
var player_items = {
	"Health Potion": {"count": 3, "heal_amount": 30},
	"Attack Boost": {"count": 2, "boost_amount": 1.5}
}


func update_question_time(delta: float) -> void:
	if question_time_left == INF: return
	
	question_time_left = max(question_time_left - delta, 0.0)
	
	# Ran out of time!
	if question_time_left == 0.0:
		# TODO: insanely hacky
		question_panel.answer_selected.emit(-2)
		question_panel.hide()
		question_time_left = INF
	
	# Display time in minutes/seconds
	var time: float = question_time_left
	var minutes: int = floor(time / 60.0)
	var seconds: int = time - minutes * 60.0
	
	timer_label.text = "Time left: %02d:%02d" % [minutes, seconds]

func entered_from_mission(data: Dictionary) -> void:
	if data == {}: return
	
	var fighting_enemy: Enemy = data["enemy_encountered"]
	
	enemy_being_fought = fighting_enemy
	enemy.enemy_resource = enemy_being_fought.enemy_resource
	enemy_max_health = enemy.enemy_resource.health
	enemy_health_value = enemy_max_health
	player_health_value = player.max_health
	
	ui.set_enemy(enemy.enemy_resource)

func prepare_enter() -> void:
	$CanvasLayer.show()
	$Camera3D.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
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
	# TODO: waiting for 1 process frame? not sure what its doing/if necessary #CAN REMOVE
	await get_tree().process_frame
	
	if player and enemy:
		player.health_change.connect(_on_player_health_changed)
		enemy.health_change.connect(_on_enemy_health_changed)
		
	if not has_node("CanvasLayer/FlashOverlay"):
		var flash_overlay = ColorRect.new()
		flash_overlay.name = "FlashOverlay"
		flash_overlay.color = Color(1, 0, 0, 0)
		flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$CanvasLayer.add_child(flash_overlay)
		
func flash_screen(correct: bool):
	var flash_overlay = $CanvasLayer/FlashOverlay
	
	if correct:
		flash_overlay.color = Color(0, 1, 0, 0.3)
	else:
		flash_overlay.color = Color(1, 0, 0, 0.3)
		
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.5)

func _process(delta: float) -> void:
	update_question_time(delta)

func setup_battle() -> void:
	question_panel.hide()
	battle_menu.hide_menu()
	
	if has_node("CanvasLayer/UI/Itempanel"):
		$CanvasLayer/UI/Itempanel.hide()
	if has_node("CanvasLayer/UI/Weaknesspanel"):
		$CanvasLayer/UI/Weaknesspanel.hide()
	
func start_turn() -> void:
	if attack_boost_turns_remaining > 0:
		attack_boost_turns_remaining = -1
		print("Attack boost: ", attack_boost_turns_remaining, " turns remaining")
	
		if attack_boost_turns_remaining <= 0:
			attack_multiplier = 1.0
			print("Attack boost has worn off")
			
	select_random_attack_options()
	
	battle_menu.show_menu()

func select_random_attack_options() -> void:
	current_attack_option = MoveLoader.selectMove(3)
	
	update_battle_menu_options()
	
func update_battle_menu_options() -> void:
	
	var options = []
	
	for i in range(3):
		if i < current_attack_option.size():
			var move = current_attack_option[i]
			options.append(move.name + " (" + str(move.damage) + " " + move.type + ")")
		else:
			options.append("ATTACK" + str(i + 1))
			
	options.append("ITEMS")
	
	battle_menu.update_options(options)

## Given an answer index 1-4, check if answer is correct
func _on_answer_selected(answer: int) -> void:
	mark_question([answer])
		
func mark_question(answers: Array[int]) -> void:
	# NOTE: if -2 is in the answers, we timed out
	var correct: bool = QuestionSelector.markQuestion(current_question, answers, current_question.answeringTime - question_time_left)
	timer_label.hide()
	
	flash_screen(correct)
	
	if correct:
		# TODO: comment this condition?
		#	is it possible to instead check current_attack != null?
		if typeof(current_attack) == TYPE_OBJECT:
			execute_attack(current_attack.damage)
	else:
		start_enemy_turn()

# TODO(minor): should be enum
func _on_option_selected(option: String) -> void:
	var move_name = option
	var damage_start = option.find("(")
	if damage_start != -1:
		move_name = option.substr(0, damage_start)
		
	print("Extracted move name: ", move_name)
	print("Number of moves to be extracted: ", current_attack_option.size())
	
	for i in range(current_attack_option.size()):
		print("Move ", i, ": ", current_attack_option[i].name)

	for move in current_attack_option:
		print("Comparing [", move_name, "] with [", move.name, "]")
		if move.name.strip_edges() == move_name.strip_edges():
			current_attack = move
			show_question_for_action()
			return
		
	if option == "ITEMS":
		show_items()
		
	else:
		print("Error: cant find move")


func show_question_for_action() -> void:
	current_question = QuestionSelector.selectQuestion(QuestionSelector.TOPIC_CYBERSECURITY | QuestionSelector.QUESTION_TYPE_SINGLE, 0.5)
	question_time_left = current_question.answeringTime
	timer_label.show()
	
	if current_question:
		question_panel.show_question(current_question)
		battle_menu.hide_menu()
	else:
		print("No question found!")

func execute_attack(damage: float = 15.0) -> void:
	lightning_tube.show()
	lightning_tube.mesh.material.set_shader_parameter("tint", lightning_player_color)
	lightning_tube.mesh.material.set_shader_parameter("direction", 1.0)
	
	# TODO: should read out value from move settings/list
	var boosted_damage = damage * attack_multiplier
	apply_damage_to_enemy(boosted_damage)
	
	if attack_multiplier > 1.0:
		print("Attack boosted! Dealt ", boosted_damage, " damage instead of", damage)

	battle_menu.hide_menu()
	start_enemy_turn()
	
func show_items() -> void:
	print("Showing items")
	
	var item_panel = $CanvasLayer/UI/Itempanel
	var item_list = $CanvasLayer/UI/Itempanel/Itemlist
	
	for child in item_list.get_children():
		child.queue_free()
	
	for item_name in player_items:
		var item_data = player_items[item_name]
		if item_data.count > 0:
			var button = Button.new()
			button.text = item_name + " (x" + str(item_data.count) + ")"
			
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0, 0, 0, 0.8)
			btn_style.border_color = Color(1, 0, 0)
			btn_style.corner_radius_top_left = 10
			btn_style.corner_radius_bottom_right = 10
			
			button.add_theme_stylebox_override("normal", btn_style)
			button.custom_minimum_size = Vector2(200, 40)
			button.connect("pressed", use_item.bind(item_name))
			item_list.add_child(button)
	
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(200, 40)
	back_button.connect("pressed", _on_back_pressed)
	item_list.add_child(back_button)
	
	battle_menu.hide_menu()
	item_panel.show()
	
func _on_back_pressed() -> void:
	$CanvasLayer/UI/Itempanel.hide()
	battle_menu.show_menu()

func use_item(item_name: String) -> void:
	var item = player_items[item_name]
	match item_name:
		"Health Potion":
			var heal = item.heal_amount
			player_health_value = min(player.max_health, player_health_value + heal)
			player.health_change.emit(player_health_value)
			item.count -= 1
		"Attack Boost":
			attack_multiplier = item.boost_amount
			attack_boost_turns_remaining = 3
			item.count -= 1
			print("Used Attack Boost, attacks increased by ", attack_multiplier, " for ", attack_boost_turns_remaining, " turns")

	$CanvasLayer/UI/Itempanel.hide()
	battle_menu.show_menu()

func start_enemy_turn() -> void:
	await get_tree().create_timer(1.0).timeout
	execute_enemy_attack()
	
func execute_enemy_attack() -> void:
	var enemy_damage: float = 10.0
	
	lightning_tube.mesh.material.set_shader_parameter("tint", lightning_enemy_color)
	lightning_tube.mesh.material.set_shader_parameter("direction", -1.0)
		
	apply_damage_to_player(enemy_damage)
	await get_tree().create_timer(1.0).timeout
	lightning_tube.hide()
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

	game_over_panel.show()
	result_label.show()

	if player_won:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	else:
		result_label.text = "DEFEAT!"
		result_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
		# TODO: go back to hub
	
	# TODO: Timer after victory (probably should be some animation that plays that we await?)
	await get_tree().create_timer(1.0).timeout

	if player_won:	
		SceneCoordinator.change_scene.emit(SceneType.Name.MISSION, { "deload_level": false })
	else:
		SceneCoordinator.change_scene.emit(SceneType.Name.HUB, { "deload_level": true })

func _on_player_health_changed(new_health: float):
	player_health.value = new_health
	if $CanvasLayer/UI/Playerhealth/Healthlabel:
		$CanvasLayer/UI/Playerhealth/Healthlabel.text = str(new_health) + "/" + str(player.max_health)
	
func _on_enemy_health_changed(new_health: float):
	enemy_health.value = new_health
	if $CanvasLayer/UI/Enemyhealth/Healthlabel:
		$CanvasLayer/UI/Enemyhealth/Healthlabel.text = str(new_health) + "/" + str(enemy_max_health)
