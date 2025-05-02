extends Control

# Flags to track interaction state
var is_in_area = false  # True if player is in the interaction area
var menu_open = false  # True if the level menu is currently open

# References to tooltip and player controller
@onready var tooltip = $"../../LevelSelectionArea/Tooltip"  # Tooltip label to guide the player
@onready var proto_controller: ProtoController = $"../../Player/ProtoController3P"  # Player input controller

func _ready():
	# Reset any previous animation states
	$AnimationPlayer.play('RESET')
	
	# Initially hide this menu
	self.visible = false
	
	# Hide tooltip at start
	if tooltip:
		tooltip.visible = false
	
	# Connect Area3D signals for detecting player proximity
	var area = get_node_or_null("../../LevelSelectionArea")
	if area:
		area.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
		area.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	else:
		print("Error: Area3D not found in the scene.")

# Closes the level selection menu and re-enables player input
func close_levels():
	$AnimationPlayer.play_backwards('load_select_level')
	self.visible = false
	menu_open = false
	proto_controller.set_all_inputs(true)  # Allow player movement

# Opens the level selection menu and disables player input
func open_levels():
	$AnimationPlayer.play('load_select_level')
	self.visible = true
	menu_open = true
	proto_controller.set_all_inputs(false)  # Prevent player movement

# Toggles the menu on player interaction (e.g. when 'E' or 'interact' is pressed)
func on_interact():
	if is_in_area and Input.is_action_just_pressed('interact'):
		if not self.visible:
			open_levels()
		else:
			close_levels()

# Called when the Back button in the level menu is pressed
func _on_back_btn_pressed() -> void:
	close_levels()

# When Level 1 button is pressed, play a transition and load the mission scene
func _on_level_1_pressed() -> void:
	var transition_screen = $"../TransitionScreen"
	
	transition_screen.visible = true
	print("Starting transition animation...")
	
	# Start fade-in transition
	$"../TransitionScreen/AnimationPlayer".play("fade_in_to_loading_screen")
	
	# Wait 1 second (simulate transition delay)
	await get_tree().create_timer(1).timeout
	
	print("Transition complete. Loading level 1...")
	
	# In the future, pass a PackedScene to load dynamically
	print("Emitting switch to mission!")
	transition_screen.visible = false
	SceneCoordinator.change_scene.emit(SceneType.Name.MISSION, {
		"deload_level": true,
		"level_name": "res://scenes/levels/mission1/level_1.tscn"
	})

# Alternate version of level 1 (e.g. from AI world) — loads different scene
func _on_level_1_ai_pressed() -> void:
	var transition_screen = $"../TransitionScreen"
	
	transition_screen.visible = true
	print("Starting transition animation...")
	
	# Start fade-in transition
	$"../TransitionScreen/AnimationPlayer".play("fade_in_to_loading_screen")
	
	# Wait 1 second
	await get_tree().create_timer(1).timeout
	
	print("Transition complete. Loading level 1 (AI path)...")
	
	# In the future, pass a PackedScene to load dynamically
	print("Emitting switch to mission!")
	transition_screen.visible = false
	SceneCoordinator.change_scene.emit(SceneType.Name.MISSION, {
		"deload_level": true,
		"level_name": "res://scenes/missions/levels/level_1.tscn"
	})

# Called every frame to check for interaction input
func _process(_delta):
	on_interact()

# Triggered when a body enters the LevelSelectionArea
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Confirm it's the player
		is_in_area = true
		if tooltip:
			tooltip.show()  # Show tooltip when player is near
	else:
		print(body.name)

# Triggered when a body exits the LevelSelectionArea
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Confirm it's the player
		is_in_area = false
		if tooltip:
			tooltip.hide()  # Hide tooltip when player leaves

# Called when Final Boss button is pressed
func _on_final_boss_pressed() -> void:
	print("Going to final boss!")
	SceneCoordinator.change_scene.emit(SceneType.Name.FINAL_BATTLE, {})
