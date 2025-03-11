extends Node3D

@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer
@onready var LevelCompleteLabel = $Area3D/LevelCompleteLabel  # Reference to the Label3D node
@onready var transition_screen = get_node("/root/Level1/TransitionScreen")
# Track whether the player is inside the level completion zone
var inside_area = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	transition_screen.visible = true
	var color_rect = $TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")
	await SceneTransitionAnimation.animation_finished
	
	transition_screen.visible = false
	
	$Area3D.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
	$Area3D.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	
	
	# Make sure the label is off at the start
	LevelCompleteLabel.visible = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	print("HEEYYYY")
	inside_area = true
	LevelCompleteLabel.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	inside_area = false
	LevelCompleteLabel.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if inside_area and Input.is_action_just_pressed("interact"):
		# Change the lvl1 value in the Global singleton
		Global.lvl1 = true
		Global.save_game()  # Save the updated value permanently
		
		print("lvl1 is now: ", Global.lvl1)

		# Scene transition
		transition_screen.visible = true
		SceneTransitionAnimation.play("fade_in_to_loading_screen")
		await $TransitionScreen/AnimationPlayer.animation_finished
		
		get_tree().change_scene_to_file("res://scenes/hub.tscn")

		
		
# Function to update the color of the Level1Block after scene transition
