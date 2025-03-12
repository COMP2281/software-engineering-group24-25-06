extends Control

# Export variables to link scenes in the Inspector
@export var ai_scene: PackedScene
@export var cyber_security_scene: PackedScene
@export var data_analytics_scene: PackedScene
@export var world_completions_area: Area3D
@export var tooltip: Label3D

var is_in_area = false  # Flag to track if the player is inside the area
var menu_open = false  # Track menu state
@onready var animation_player = $AnimationPlayer  # Adjust path as needed

func _ready():
	#animation_player.play("RESET")
	# Connect button signals using Callable
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/AI.connect("pressed", Callable(self, "_on_ai_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/CyberSecurity.connect("pressed", Callable(self, "_on_cyber_security_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/DataAnalytics.connect("pressed", Callable(self, "_on_data_analytics_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/TitleHContainer/BackBtn.connect("pressed", Callable(self, "_on_back_btn_pressed"))

	if tooltip:
		tooltip.visible = false
		# Connect the signals for the area3D
		
	var area = world_completions_area
	if area:
		area.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
		area.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	else:
		print("Error: Area3D not found in the scene.")
	
# Handle AI button press
func _on_ai_pressed() -> void:
	if ai_scene:
		get_tree().change_scene_to_packed(ai_scene)  # Use the PackedScene variable
	else:
		print("AI scene not linked!")

# Handle Cyber Security button press
func _on_cyber_security_pressed() -> void:
	# Hide WorldSelect
	$".".visible = false  # Hide the WorldSelect node

	# Show CyberSecurity
	var cyber_security = $"../CyberSecurity"
	if cyber_security:
		#print(cyber_security)
		cyber_security.visible = true  # Show the CyberSecurity node
	else:
		print("CyberSecurity node not found!")


# Handle Data Analytics button press
func _on_data_analytics_pressed() -> void:
	if data_analytics_scene:
		get_tree().change_scene_to_packed(data_analytics_scene)  # Use the PackedScene variable
	else:
		print("Data Analytics scene not linked!")

# Handle Back button press
func _on_back_btn_pressed() -> void:
	close_menu()

# Called every frame
func _process(delta: float):
	# Check for 'interact' button press when inside the area
	if Input.is_action_just_pressed("interact") and is_in_area:
		on_interact()  # Trigger the interact event

# Handle the interaction event (open/close menu)
func on_interact():
	if menu_open:
		close_menu()
	else:
		open_menu()
		
func open_menu():
	var hub = $"../.."
	hub.visible = false
	animation_player.play("fade_in")
	self.visible = true
	menu_open = true
	_enable_player_controls(false)  # Disable movement
	_release_mouse()  # Make cursor visible

func close_menu():
	var hub = $"../.."
	hub.visible = true
	animation_player.play_backwards("fade_in")
	self.visible = false
	menu_open = false
	_enable_player_controls(true)  # Re-enable movement
	_capture_mouse()  # Lock mouse back in


# Area3D trigger functions
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Ensure it's the player
		print("Player entered the area.")
		is_in_area = true
		if tooltip:
			tooltip.visible = true  # Show tooltip

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Ensure it's the player
		print("Player exited the area.")
		is_in_area = false
		if tooltip:
			tooltip.visible = false  # Hide tooltips

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
