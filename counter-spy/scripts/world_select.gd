extends Control

# Exported PackedScene variables allow linking scenes in the editor
@export var ai_scene: PackedScene
@export var cyber_security_scene: PackedScene
@export var data_analytics_scene: PackedScene

# Exported scene references - linked in the editor
@export var world_completions_area: Area3D  # Detects when the player is nearby
@export var tooltip: Label3D  # Tooltip shown when player is in interaction area

# Get a reference to the player’s ProtoController (assumed for input control)
@onready var proto_controller: ProtoController = $"../../Player/ProtoController3P"

var is_in_area: bool = false  # True if player is inside the Area3D trigger zone
var menu_open: bool = false  # Tracks if the menu is currently open
@onready var animation_player = $AnimationPlayer  # Controls fade animation

func _ready():
	# Connect buttons in the WorldSelect UI to their respective handlers
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/AI.connect("pressed", Callable(self, "_on_ai_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/CyberSecurity.connect("pressed", Callable(self, "_on_cyber_security_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/DataAnalytics.connect("pressed", Callable(self, "_on_data_analytics_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/TitleHContainer/BackBtn.connect("pressed", Callable(self, "_on_back_btn_pressed"))

	# Initially hide tooltip until player enters area
	if tooltip:
		tooltip.visible = false

	# Connect signals for when a body enters or exits the Area3D
	var area = world_completions_area
	if area:
		area.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
		area.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	else:
		print("Error: Area3D not found in the scene.")
	
func _on_ai_pressed() -> void:
	if ai_scene:
		get_tree().change_scene_to_packed(ai_scene)  # Switch to AI scene
	else:
		print("AI scene not linked!")

func _on_cyber_security_pressed() -> void:
	$".".visible = false  # Hide the current WorldSelect menu
	var cyber_security = $"../CyberSecurity"
	if cyber_security:
		cyber_security.visible = true  # Show the Cyber Security world
	else:
		print("CyberSecurity node not found!")

func _on_data_analytics_pressed() -> void:
	if data_analytics_scene:
		get_tree().change_scene_to_packed(data_analytics_scene)  # Switch to Data Analytics scene
	else:
		print("Data Analytics scene not linked!")

# Called when Back button is pressed
func _on_back_btn_pressed() -> void:
	close_menu()

# Called every frame
func _process(delta: float):
	# If player is in area and presses 'interact', open/close menu
	if Input.is_action_just_pressed("interact") and is_in_area:
		on_interact()

# Toggle menu visibility when interacting
func on_interact():
	if menu_open:
		close_menu()
	else:
		open_menu()

# Show the world select menu and disable player controls
func open_menu():
	var hub = $"../.."
	hub.visible = false  # Hide the hub interface
	animation_player.play("fade_in")  # Play opening animation
	self.visible = true  # Show this menu
	menu_open = true
	proto_controller.set_all_inputs(false)  # Prevent player movement

# Hide the menu and re-enable player controls
func close_menu():
	var hub = $"../.."
	hub.visible = true  # Show the hub interface
	animation_player.play_backwards("fade_in")  # Play closing animation
	self.visible = false  # Hide this menu
	menu_open = false
	proto_controller.set_all_inputs(true)  # Allow player movement again

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Ensure it's the player
		print("Player entered the area.")
		is_in_area = true
		if tooltip:
			tooltip.visible = true  # Show the tooltip label

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Ensure it's the player
		print("Player exited the area.")
		is_in_area = false
		if tooltip:
			tooltip.visible = false  # Hide the tooltip
