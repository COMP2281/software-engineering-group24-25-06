extends Node3D

# References to key nodes for scene transitions and label display
@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer
@onready var LevelCompleteLabel = $Area3D/LevelCompleteLabel  # Label3D shown when player is in completion zone
@onready var transition_screen = get_node("/root/Level1/TransitionScreen")  # Global path to transition overlay

# Track if the player is currently in the level completion area
var inside_area = false

# Called when the scene starts
func _ready() -> void:
	# Start with the transition screen visible and black
	transition_screen.visible = true
	var color_rect = $TransitionScreen/ColorRect
	color_rect.color = Color(0, 0, 0, 1)  # Full black screen
	
	# Play the fade-out animation (from black to game view)
	SceneTransitionAnimation.play("fade_out_to_level")
	await SceneTransitionAnimation.animation_finished
	
	# Hide the transition screen after animation finishes
	transition_screen.visible = false
	
	# Connect signals for when the player enters/exits the level completion trigger
	$Area3D.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
	$Area3D.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	
	# Hide the level completion label at the beginning
	LevelCompleteLabel.visible = false

# Triggered when a body (e.g., player) enters the level end area
func _on_area_3d_body_entered(body: Node3D) -> void:
	print("HEEYYYY")  # Debug log
	inside_area = true
	LevelCompleteLabel.visible = true  # Show message prompting interaction

# Triggered when the body leaves the level end area
func _on_area_3d_body_exited(body: Node3D) -> void:
	inside_area = false
	LevelCompleteLabel.visible = false  # Hide the label again

# Called every frame — checks for player interaction when in area
func _process(delta: float) -> void:
	if inside_area and Input.is_action_just_pressed("interact"):
		# Mark the level as completed in global state
		Global.lvl1 = true
		Global.save_game()  # Persist completion to save file
		
		print("lvl1 is now: ", Global.lvl1)  # Debug print

		# Begin transition to the hub scene
		transition_screen.visible = true
		SceneTransitionAnimation.play("fade_in_to_loading_screen")
		await $TransitionScreen/AnimationPlayer.animation_finished
		
		# Switch to hub scene
		get_tree().change_scene_to_file("res://scenes/hub.tscn")

# Function stub (comment placeholder) — add here if you want to update Level1Block visuals after transition
# func update_level_block():
#     pass
