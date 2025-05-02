class_name EncounterNode extends Node3D

# Reference to main battle characters
@onready var player: PlayerBattle = $player
@onready var enemy: EnemyBattle = $enemy

# UI elements
@onready var player_health = $CanvasLayer/UI/Playerhealth
@onready var enemy_health = $CanvasLayer/UI/Enemyhealth
@onready var battle_menu = $CanvasLayer/UI/Battlemenu
@onready var question_panel = $CanvasLayer/UI/Questionpanel
@onready var ui = $CanvasLayer/UI
@onready var timer_label = $CanvasLayer/UI/Timerlabel
@onready var lightning_tube : MeshInstance3D = $LightningTube

# Colors for attack effects
@export_color_no_alpha var lightning_player_color: Color
@export_color_no_alpha var lightning_enemy_color: Color

# Health tracking variables
var player_health_value: float = 0.0
var enemy_health_value: float = 0.0
var enemy_max_health: float = 0.0

# Battle state variables
var player_defense: bool = false  # If the player is defending
var current_turn: String = "player"  # Whose turn is it currently
var current_attack = null  # Current attack being used

# Enemy & question management
var enemy_being_fought: Enemy = null  # Reference to the enemy being fought
var current_question: Question = null  # Current question being asked
var question_time_left: float = INF  # Time left to answer current question
var enemy_is_boss: bool = false  # Is this a boss battle?

# Attack modifiers
var attack_multiplier: float = 1.0  # Multiplier for attack damage
var attack_boost_turns_remaining: int = 0  # How many turns of attack boost remain

# Current attack options the player can choose from
var current_attack_option: Array[Move] = []

# Reference to boss enemy resource
var boss_enemy_resource: EnemyResource = load("res://settings/enemy/boss_enemy.tres")

# Player inventory
var player_items = {
	"Health Potion": {"count": 3, "heal_amount": 30},
	"Attack Boost": {"count": 2, "boost_amount": 1.5}
}

# Visual effects
@onready var attack_particles: CPUParticles3D = $CPUParticles3D
var impact_sound: AudioStreamPlayer

# Initialize sound effects
func setup_effects():
	# Create or get a reference to the impact sound player
	if not has_node("ImpactSound"):
		impact_sound = AudioStreamPlayer.new()
		impact_sound.name = "ImpactSound"
		add_child(impact_sound)
	else:
		impact_sound = $ImpactSound

# Update question timer and handle timeout
func update_question_time(delta: float) -> void:
	if question_time_left == INF: return
	
	# Decrease timer
	question_time_left = max(question_time_left - delta, 0.0)
	
	# Handle timeout
	if question_time_left == 0.0:
		# Emit signal with -2 to indicate timeout
		question_panel.answer_selected.emit(-2)
		question_panel.hide()
		question_time_left = INF
	
	# Update timer display
	var time: float = question_time_left
	var minutes: int = floor(time / 60.0)
	var seconds: int = time - minutes * 60.0
	
	timer_label.text = "Time left: %02d:%02d" % [minutes, seconds]

# Set up the battle when entering from mission scene
func entered_from_mission(data: Dictionary) -> void:
	if data == {}: return
	
	# Extract enemy from mission data
	var fighting_enemy: Enemy = data["enemy_encountered"]
	
	# Initialize battle state
	enemy_being_fought = fighting_enemy
	enemy.enemy_resource = enemy_being_fought.enemy_resource
	enemy_max_health = enemy.enemy_resource.health
	enemy_health_value = enemy_max_health
	player_health_value = player.max_health
	
	# Show regular enemy, hide boss
	$bigBonsaiWithRedEyes.hide()
	$enemy.show()
	
	# Update UI with enemy info
	ui.set_enemy(enemy.enemy_resource)
	
# Set up for the final boss battle
func entered_from_final_battle() -> void:
	# Use boss enemy stats
	enemy_max_health = boss_enemy_resource.health
	enemy_health_value = enemy_max_health
	player_health_value = player.max_health
	enemy_is_boss = true
	
	# Show boss model, hide regular enemy
	$bigBonsaiWithRedEyes.show()
	$enemy.hide()
	
	# Update UI with boss info
	ui.set_enemy(boss_enemy_resource)

# Prepare UI and input when entering the battle scene
func prepare_enter() -> void:
	$CanvasLayer.show()
	$Camera3D.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Hide game over elements initially
	var game_over_panel = $CanvasLayer/UI/Gameoverpanel
	var result_label = $CanvasLayer/UI/Gameoverpanel/Resultlabel
	
	game_over_panel.hide()
	result_label.hide()
	
# Clean up when exiting the battle scene
func prepare_exit() -> void:
	$CanvasLayer.hide()
	
	if $Camera3D.current:
		$Camera3D.clear_current(true)

# Initialize battle scene
func _ready() -> void:
	# Set up battle UI and effects
	setup_battle()
	setup_enhanced_health_bars()
	setup_effects() 
	
	# Connect signals
	battle_menu.connect("option_selected", _on_option_selected)
	question_panel.connect("answer_selected", _on_answer_selected)
	
	# Start player's turn
	start_turn()
	
	# Wait for one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Connect health change signals
	if player and enemy:
		player.health_change.connect(_on_player_health_changed)
		enemy.health_change.connect(_on_enemy_health_changed)
	
	# Create flash overlay for visual feedback
	if not has_node("CanvasLayer/FlashOverlay"):
		var flash_overlay = ColorRect.new()
		flash_overlay.name = "FlashOverlay"
		flash_overlay.color = Color(1, 0, 0, 0)
		flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$CanvasLayer.add_child(flash_overlay)
		
# Flash the screen to indicate correct/incorrect answer
func flash_screen(correct: bool):
	var flash_overlay = $CanvasLayer/FlashOverlay
	
	# Green flash for correct, red for incorrect
	if correct:
		flash_overlay.color = Color(0, 1, 0, 0.3)
	else:
		flash_overlay.color = Color(1, 0, 0, 0.3)
	
	# Fade out the flash effect
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.5)

# Main game loop
func _process(delta: float) -> void:
	update_question_time(delta)

# Set up the initial battle UI state
func setup_battle() -> void:
	# Hide panels that aren't needed immediately
	question_panel.hide()
	battle_menu.hide_menu()
	
	if has_node("CanvasLayer/UI/Itempanel"):
		$CanvasLayer/UI/Itempanel.hide()
	if has_node("CanvasLayer/UI/Weaknesspanel"):
		$CanvasLayer/UI/Weaknesspanel.hide()
	
# Start player's turn
func start_turn() -> void:
	# Manage attack boost duration
	if attack_boost_turns_remaining > 0:
		attack_boost_turns_remaining -= 1
		print("Attack boost: ", attack_boost_turns_remaining, " turns remaining")
	
		if attack_boost_turns_remaining <= 0:
			attack_multiplier = 1.0
			print("Attack boost has worn off")
	
	# Select random attack options for this turn
	select_random_attack_options()
	
	# Show the battle menu
	battle_menu.show_menu()

# Select random attack moves of different types for the player to choose from
func select_random_attack_options() -> void:
	# List of possible attack types
	var types = ["fire","generic","water","plant"]
	types.shuffle()
	
	current_attack_option = []
	
	# Try to get one move of each type for variety
	for i in range(min(3, types.size())):
		var type_moves = []
		
		# Collect moves of the current type
		for move in MoveLoader.loadedMoves:
			if move.type == types[i]:
				type_moves.append(move)
		
		# Add a random move of this type if available
		if type_moves.size() > 0:
			type_moves.shuffle()
			current_attack_option.append(type_moves[0])
	
	# Fill remaining slots with any move types if needed
	while current_attack_option.size() < 3:
		var all_moves = MoveLoader.loadedMoves.duplicate()
		all_moves.shuffle()
		
		for move in all_moves:
			if move not in current_attack_option:
				current_attack_option.append(move)
				break
	
	# Update the UI with new options
	update_battle_menu_options()
	
# Update the battle menu with current attack options
func update_battle_menu_options() -> void:
	var options = []
	
	# Format each attack option with name, damage and type
	for i in range(3):
		if i < current_attack_option.size():
			var move = current_attack_option[i]
			options.append(move.name + " (" + str(move.damage) + " " + move.type + ")")
		else:
			options.append("ATTACK" + str(i + 1))
	
	# Add items option
	options.append("ITEMS")
	
	# Update the menu UI
	battle_menu.update_options(options)

# Handle player's question answer
func _on_answer_selected(answer: int) -> void:
	mark_question([answer])
		
# Check if the answer is correct and proceed accordingly
func mark_question(answers: Array[int]) -> void:
	# Check if answer is correct (-2 indicates timeout)
	var correct: bool = QuestionSelector.markQuestion(current_question, answers, current_question.answeringTime - question_time_left)
	timer_label.hide()
	
	# Visual feedback on answer
	flash_screen(correct)
	
	if correct:
		# If correct, execute the attack
		if typeof(current_attack) == TYPE_OBJECT:
			execute_attack(current_attack.damage)
	else:
		# If incorrect, skip player's turn
		start_enemy_turn()

# Handle player's menu option selection
func _on_option_selected(option: String) -> void:
	# Extract move name from option text
	var move_name = option
	var damage_start = option.find("(")
	if damage_start != -1:
		move_name = option.substr(0, damage_start)
		
	print("Extracted move name: ", move_name)
	print("Number of moves to be extracted: ", current_attack_option.size())
	
	# Debug logging
	for i in range(current_attack_option.size()):
		print("Move ", i, ": ", current_attack_option[i].name)

	# Find the selected move
	for move in current_attack_option:
		print("Comparing [", move_name, "] with [", move.name, "]")
		if move.name.strip_edges() == move_name.strip_edges():
			current_attack = move
			show_question_for_action()
			return
	
	# Handle non-attack options
	if option == "ITEMS":
		show_items()
	else:
		print("Error: cant find move")

# Show a question that player must answer to execute their action
func show_question_for_action() -> void:
	# Select a cybersecurity question
	current_question = QuestionSelector.selectQuestion(QuestionSelector.TOPIC_CYBERSECURITY | QuestionSelector.QUESTION_TYPE_SINGLE, 0.5)
	question_time_left = current_question.answeringTime
	timer_label.show()
	
	if current_question:
		question_panel.show_question(current_question)
		battle_menu.hide_menu()
	else:
		print("No question found!")

# Execute the player's attack with visual effects
func execute_attack(damage: float = 15.0) -> void:
	# Show lightning effect
	lightning_tube.show()
	lightning_tube.mesh.material.set_shader_parameter("tint", lightning_player_color)
	lightning_tube.mesh.material.set_shader_parameter("direction", 1.0)
	
	# Determine attack type
	var attack_type = "generic"
	if current_attack is Object:
		var check_type = current_attack.get("type")
		print("Here is check_type ", check_type)
		if check_type != null:
			attack_type = check_type
	else:
		print("Attack type is unknown?", current_attack)
	
	# Configure particle effects based on attack type
	attack_particles.emitting = false
	attack_particles.global_position = enemy.global_position
	
	match attack_type:
		"fire":
			# Fire effect - orange/red particles rising up
			attack_particles.mesh.get_material().albedo_color = Color(1.0, 0.3, 0.0)
			attack_particles.gravity = Vector3(0, 8, 0)
			attack_particles.initial_velocity_min = 3.0
			attack_particles.initial_velocity_max = 8.0
			attack_particles.scale = Vector3(0.5, 0.5, 0.5)
			
		"water":
			# Water effect - blue particles falling down
			attack_particles.mesh.get_material().albedo_color = Color(0.0, 0.6, 1.0)
			attack_particles.gravity = Vector3(0, -15, 0)
			attack_particles.initial_velocity_min = 2.0
			attack_particles.initial_velocity_max = 6.0
			attack_particles.scale = Vector3(0.4, 0.4, 0.4)
			
		"plant":
			# Plant effect - green particles with slight fall
			attack_particles.mesh.get_material().albedo_color = Color(0.1, 1.0, 0.1)
			attack_particles.gravity = Vector3(0, -2, 0)
			attack_particles.initial_velocity_min = 2.0
			attack_particles.initial_velocity_max = 4.0
			attack_particles.scale = Vector3(0.5, 0.5, 0.5)
			
		_:
			# Generic effect - white particles with no gravity
			attack_particles.mesh.get_material().albedo_color = Color(1.0, 1.0, 1.0)
			attack_particles.gravity = Vector3(0, 0, 0)
			attack_particles.initial_velocity_min = 5.0
			attack_particles.initial_velocity_max = 10.0
			attack_particles.scale = Vector3(0.4, 0.4, 0.4)
	
	# Apply knockback visual effect to enemy
	var original_position = enemy.global_position
	var knockback_direction = (enemy.global_position - player.global_position).normalized()
	knockback_direction.y = 0.2  # Add slight upward component
	
	var knockback_tween = create_tween()
	knockback_tween.tween_property(enemy, "global_position", 
		original_position + knockback_direction * 0.5, 0.1)  # Quick knockback
	knockback_tween.tween_property(enemy, "global_position", 
		original_position, 0.3)  # Return to position
	
	# Position particle effect at impact point
	var impact_position = enemy.global_position - (enemy.global_position - player.global_position).normalized() * 0.5
	attack_particles.global_position = impact_position
	
	# Start particle emission
	attack_particles.emitting = true
	
	# Delay for visual sync before applying damage
	await get_tree().create_timer(0.1).timeout

	# Apply damage with any active multipliers
	var boosted_damage = damage * attack_multiplier
	apply_damage_to_enemy(boosted_damage)
	
	if attack_multiplier > 1.0:
		print("Attack boosted! Dealt ", boosted_damage, " damage instead of", damage)

	# Hide menu and start enemy turn
	battle_menu.hide_menu()
	start_enemy_turn()
	
# Display item inventory panel
func show_items() -> void:
	print("Showing items")
	
	var item_panel = $CanvasLayer/UI/Itempanel
	var item_list = $CanvasLayer/UI/Itempanel/Itemlist
	
	# Clear existing items
	for child in item_list.get_children():
		child.queue_free()
	
	item_panel.position = Vector2(50, 100)
	
	item_list.add_theme_constant_override("separation", 15) 
	
	# Create buttons for each available item
	for item_name in player_items:
		var item_data = player_items[item_name]
		if item_data.count > 0:
			var button = Button.new()
			button.text = item_name + " (x" + str(item_data.count) + ")"
			
			# Style the button
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0, 0, 0, 0.8)
			btn_style.border_color = Color(1, 0, 0)
			btn_style.corner_radius_top_left = 10
			btn_style.corner_radius_bottom_right = 10
			
			var hover_style = btn_style.duplicate()
			hover_style.bg_color = Color(0.4, 0, 0, 0.9)
			
			button.add_theme_stylebox_override("normal", btn_style)
			button.add_theme_stylebox_override("hover", hover_style)
			button.custom_minimum_size = Vector2(200, 40)
			button.connect("pressed", use_item.bind(item_name))
			item_list.add_child(button)
			
			# Fade in animation
			button.modulate.a = 0
			item_list.add_child(button)
			
			var tween = create_tween()
			tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(item_list.get_child_count() * 0.1)
	
	# Add back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(200, 40)
	
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0, 0, 0, 0.8)
	back_style.border_color = Color(1, 0, 0)
	back_style.corner_radius_top_left = 10
	back_style.corner_radius_bottom_right = 10
	
	var back_hover = back_style.duplicate()
	back_hover.bg_color = Color(0.4, 0, 0, 0.9)
	
	back_button.add_theme_stylebox_override("normal", back_style)
	back_button.add_theme_stylebox_override("hover", back_hover)
	back_button.connect("pressed", _on_back_pressed)
	item_list.add_child(back_button)
	
	# Fade in animation for back button
	back_button.modulate.a = 0
	item_list.add_child(back_button)
	
	var back_tween = create_tween()
	back_tween.tween_property(back_button, "modulate:a", 1.0, 0.2).set_delay(item_list.get_child_count() * 0.1)
	
	item_panel.modulate.a = 0
	
	battle_menu.hide_menu()
	
	# Fade in the whole panel
	var panel_tween = create_tween()
	panel_tween.tween_property(item_panel, "modulate:a", 1.0, 0.3)
	
	item_panel.show()
	
# Handle back button press in item menu
func _on_back_pressed() -> void:
	var item_panel = $CanvasLayer/UI/Itempanel
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(item_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(item_panel.hide)
	
	battle_menu.show_menu()
	
	# Fade in battle menu buttons
	for i in range(battle_menu.buttons.size()):
		var button = battle_menu.buttons[i]
		button.modulate.a = 0
	   
		var button_tween = create_tween()
		button_tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(i * 0.1)
	
# Use a selected item
func use_item(item_name: String) -> void:
	var item = player_items[item_name]
	match item_name:
		"Health Potion":
			# Heal player
			var heal = item.heal_amount
			player_health_value = min(player.max_health, player_health_value + heal)
			player.health_change.emit(player_health_value)
			item.count -= 1
		"Attack Boost":
			# Boost attack damage for next few turns
			attack_multiplier = item.boost_amount
			attack_boost_turns_remaining = 3
			item.count -= 1
			print("Used Attack Boost, attacks increased by ", attack_multiplier, " for ", attack_boost_turns_remaining, " turns")

	# Hide item panel and return to battle menu
	$CanvasLayer/UI/Itempanel.hide()
	battle_menu.show_menu()

# Start the enemy's turn
func start_enemy_turn() -> void:
	# Short delay before enemy attack
	await get_tree().create_timer(1.0).timeout
	execute_enemy_attack()
	
# Execute the enemy's attack with visual effects
func execute_enemy_attack() -> void:
	var enemy_damage: float = 20.0
	
	# Set up lightning effect for enemy attack
	lightning_tube.mesh.material.set_shader_parameter("tint", lightning_enemy_color)
	lightning_tube.mesh.material.set_shader_parameter("direction", -1.0)
	
	# Configure particle effects for enemy attack
	attack_particles.emitting = false
	attack_particles.global_position = player.global_position
	attack_particles.mesh.get_material().albedo_color = Color(0.9, 0.2, 0.2)  # Red for enemy attacks
	attack_particles.gravity = Vector3(0, 0, 0)
	attack_particles.initial_velocity_min = 3.0
	attack_particles.initial_velocity_max = 6.0
	
	# Apply knockback effect to player
	var original_position = player.global_position
	var knockback_direction = (player.global_position - enemy.global_position).normalized()
	knockback_direction.y = 0.2
	
	var knockback_tween = create_tween()
	knockback_tween.tween_property(player, "global_position", 
		original_position + knockback_direction * 0.5, 0.1)
	knockback_tween.tween_property(player, "global_position", 
		original_position, 0.3)
	
	# Start particle emission
	attack_particles.emitting = true
	
	# Delay before applying damage
	await get_tree().create_timer(0.1).timeout
	
	apply_damage_to_player(enemy_damage)
	
	# Delay after attack
	await get_tree().create_timer(1.0).timeout
	lightning_tube.hide()
	
	# Start player's turn
	start_turn()
	
# Apply damage to player and check for game over
func apply_damage_to_player(damage: float) -> void:
	player_health_value -= damage
	player_health_value = clamp(player_health_value, 0.0, player.max_health)
	player.health_change.emit(player_health_value)
	
	# Check for player defeat
	if player_health_value == 0.0:
		game_over(false)

# Apply damage to enemy and check for game over
func apply_damage_to_enemy(damage: float) -> void:
	enemy_health_value -= damage
	enemy_health_value = clamp(enemy_health_value, 0.0, enemy_max_health)
	enemy.health_change.emit(enemy_health_value)
	
	# Check for enemy defeat
	if enemy_health_value <= 0:
		game_over(true)

# Handle end of battle (victory or defeat)
func game_over(player_won: bool) -> void:
	battle_menu.hide_menu()
	question_panel.hide()
	
	var game_over_panel = $CanvasLayer/UI/Gameoverpanel
	var result_label = $CanvasLayer/UI/Gameoverpanel/Resultlabel

	game_over_panel.show()
	result_label.show()

	# Show appropriate victory/defeat message
	if player_won:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	else:
		result_label.text = "DEFEAT!"
		result_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
	
	# Short delay before transitioning scenes
	await get_tree().create_timer(1.0).timeout
	
	# Handle scene transition based on battle result
	if enemy_is_boss:
		# If boss was defeated, go to reflective activity
		SceneCoordinator.change_scene.emit(SceneType.Name.REFLECTIVE_ACTIVITY, {})
		return

	if player_won:	
		# Return to mission with enemy defeated
		SceneCoordinator.change_scene.emit(SceneType.Name.MISSION, { "enemy_defeated": enemy_being_fought, "deload_level": false, "level_name": "keep" })
	else:
		# Return to hub after defeat
		SceneCoordinator.change_scene.emit(SceneType.Name.HUB, { "deload_level": true })

# Handle player health bar changes with animation
func _on_player_health_changed(new_health: float):
	# Smooth animation for health bar
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(player_health, "value", new_health, 0.5)
	
	# Flash effect when taking damage
	if new_health < player_health.value:
		var style = player_health.get_theme_stylebox("fill").duplicate()
		var original_color = style.bg_color
		
		var flash_tween = create_tween()
		flash_tween.tween_method(
			func(c): 
				style.bg_color = c
				player_health.add_theme_stylebox_override("fill", style),
				Color(1, 1, 1, 1),  # Flash to white
				original_color,     # Back to original
				0.3                 # Duration
		)
	
	# Update health text
	if $CanvasLayer/UI/Playerhealth/Healthlabel:
		$CanvasLayer/UI/Playerhealth/Healthlabel.text = str(new_health) + "/" + str(player.max_health)
	
# Handle enemy health bar changes with animation
func _on_enemy_health_changed(new_health: float):
	# Smooth animation for health bar
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(enemy_health, "value", new_health, 0.5)
	
	# Flash effect when taking damage
	if new_health < enemy_health.value:
		var style = enemy_health.get_theme_stylebox("fill").duplicate()
		var original_color = style.bg_color
		
		var flash_tween = create_tween()
		flash_tween.tween_method(
			func(c): 
				style.bg_color = c
				enemy_health.add_theme_stylebox_override("fill", style),
				Color(1, 1, 1, 1),  # Flash to white
				original_color,     # Back to original
				0.3                 # Duration
		)
	
	# Update health text
	if $CanvasLayer/UI/Enemyhealth/Healthlabel:
		$CanvasLayer/UI/Enemyhealth/Healthlabel.text = str(new_health) + "/" + str(enemy_max_health)

# Configure health bars with enhanced visuals
func setup_enhanced_health_bars():
	# Configure player health bar
	player_health.custom_minimum_size = Vector2(250, 40)  # Bigger bar
	
	# Style for player health bar (blue)
	var player_style = StyleBoxFlat.new()
	player_style.bg_color = Color(0.2, 0.6, 1.0)  # Blue
	player_style.border_color = Color(0.1, 0.3, 0.8)
	player_style.shadow_color = Color(0, 0, 0, 0.3)
	player_style.shadow_size = 5
	
	player_health.add_theme_stylebox_override("fill", player_style)
	
	# Background style for health bars
	var player_bg = StyleBoxFlat.new()
	player_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	player_bg.border_color = Color(0.3, 0.3, 0.3)
	
	player_health.add_theme_stylebox_override("background", player_bg)
	
	# Configure enemy health bar
	enemy_health.custom_minimum_size = Vector2(250, 40)
	
	# Style for enemy health bar (red)
	var enemy_style = StyleBoxFlat.new()
	enemy_style.bg_color = Color(1.0, 0.2, 0.2)  # Red
	enemy_style.border_color = Color(0.8, 0.1, 0.1)
	enemy_style.shadow_color = Color(0, 0, 0, 0.3)
	enemy_style.shadow_size = 5
	
	enemy_health.add_theme_stylebox_override("fill", enemy_style)
	
	# Use duplicate of player background style for enemy
	var enemy_bg = player_bg.duplicate()
	enemy_health.add_theme_stylebox_override("background", enemy_bg)
