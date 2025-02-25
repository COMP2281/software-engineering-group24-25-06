extends Control

var is_in_area = false
var menu_open = false  # Track menu state
var lvl1 = preload("res://scenes/level_1.tscn")

@onready var tooltip = $"../LevelSelectionArea/Tooltip" # Adjust this path if needed



func _ready():
	$AnimationPlayer.play('RESET')
	self.visible = false
	
	# Ensure tooltip starts hidden
	if tooltip:
		tooltip.visible = false
	
	# Connect the signals for the area3D
	var area = get_node_or_null("../LevelSelectionArea")
	if area:
		area.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
		area.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	else:
		print("Error: Area3D not found in the scene.")

func close_levels():
	$AnimationPlayer.play_backwards('load_select_level')
	self.visible = false
	menu_open = false
	_enable_player_controls(true)  # Re-enable movement
	_capture_mouse()  # Lock mouse back in

func open_levels():
	$AnimationPlayer.play('load_select_level')
	self.visible = true
	menu_open = true
	_enable_player_controls(false)  # Disable movement
	_release_mouse()  # Make cursor visible

func on_interact():
	if is_in_area and Input.is_action_just_pressed('interact'):
		if not self.visible:
			open_levels()
		else:
			close_levels()

func _on_back_btn_pressed() -> void:
	close_levels()

func _on_level_1_pressed() -> void:
	var transition_screen = get_node("/root/Hub/CanvasLayer/TransitionScreen")
	
	transition_screen.visible = true
	print("Starting transition animation...")
	# Play the fade-out animation
	$"../CanvasLayer/TransitionScreen/AnimationPlayer".play("fade_in_to_loading_screen")
	# Wait for the animation to finish before changing the scene
	await get_tree().create_timer(2).timeout
	print("Transition complete. Loading level 1...")
	get_tree().change_scene_to_packed(lvl1)
	#transition_screen.visible = false

func _process(delta):
	on_interact()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "ProtoController":  # Ensure it's the player
		print("Player entered the area.")
		is_in_area = true
		if tooltip:
			tooltip.visible = true  # Show tooltip

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "ProtoController":  # Ensure it's the player
		print("Player exited the area.")
		is_in_area = false
		if tooltip:
			tooltip.visible = false  # Hide tooltip

## ---------------------------
## Helper functions
## ---------------------------

# Makes cursor visible when menu is open
func _release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Locks cursor back into game when menu is closed
func _capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Enable/Disable player movement
func _enable_player_controls(enable: bool):
	var player = get_node_or_null("../ProtoController")  # Adjust path if needed
	if player:
		player.can_move = enable
		player.can_jump = enable
		player.can_sprint = enable
		player.can_freefly = enable
		player.mouse_captured = enable  # Prevents mouse look
		if enable:
			player.capture_mouse()  # Re-locks cursor when closing menu
		else:
			player.release_mouse()  # Unlocks cursor when opening menu
