extends Control

var is_in_area = false
var menu_open = false  # Track menu state

@onready var level_select_area = $"../../LevelSelectionArea"
@onready var tooltip = $"../../LevelSelectionArea/Tooltip" # Adjust this path if needed
@onready var proto_controller : ProtoController = $"../../Player/ProtoController3P"

func _ready():
	$AnimationPlayer.play('RESET')
	self.visible = false
	
	# Ensure tooltip starts hidden
	if tooltip:
		tooltip.visible = false
	
	# Connect the signals for the area3D
	if level_select_area:
		level_select_area.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
		level_select_area.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	else:
		print("Error: Area3D not found in the scene.")

func close_levels():
	$AnimationPlayer.play_backwards('load_select_level')
	self.visible = false
	menu_open = false
	proto_controller.set_all_inputs(false)  # Enable movement

func open_levels():
	$AnimationPlayer.play('load_select_level')
	self.visible = true
	menu_open = true
	proto_controller.set_all_inputs(false)  # Disable movement

func on_interact():
	if is_in_area and Input.is_action_just_pressed('interact'):
		if not self.visible:
			open_levels()
		else:
			close_levels()

func _on_back_btn_pressed() -> void:
	close_levels()

func _on_level_1_pressed() -> void:
	var transition_screen = $"../TransitionScreen"
	
	transition_screen.visible = true
	print("Starting transition animation...")
	# Play the fade-out animation
	$"../TransitionScreen/AnimationPlayer".play("fade_in_to_loading_screen")
	# Wait for the animation to finish before changing the scene
	await get_tree().create_timer(1).timeout
	
	SceneCoordinator.change_scene.emit(SceneType.Name.MISSION, {"level_name": "res://scenes/levels/mission1/level_1.tscn", "reset_level": true})

func _process(delta):
	on_interact()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Ensure it's the player
		print("Player entered the area.")
		is_in_area = true
		if tooltip:
			tooltip.visible = true  # Show tooltip
	else:
		print("Body entered level select area that wasn't player: ", body.name)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "ProtoController3P":  # Ensure it's the player
		print("Player exited the area.")
		is_in_area = false
		if tooltip:
			tooltip.visible = false  # Hide tooltip
