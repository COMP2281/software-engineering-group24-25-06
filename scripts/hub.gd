extends Node3D

@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer
@onready var transition_screen = get_node("/root/Hub/TransitionScreen")
@onready var world_completions_label = $WorldCompletionsArea/Label3D  # Adjust the path as needed
@onready var world_menu = $WorldSelect
@onready var cyber_menu = $CyberSecurity

var is_inside_completion_area = false  # Flag to track if the player is inside the area

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	transition_screen.visible = true
	update_blocks()
	var color_rect = $TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")
	await SceneTransitionAnimation.animation_finished
	
	transition_screen.visible = false
	
	#world_completions_label.visible = false
	
	world_menu.visible = false
	cyber_menu.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	## Check if the player presses the 'interact' button (e.g., 'ui_accept')
	#if Input.is_action_just_pressed("interact") and is_inside_completion_area:
		#print("you interacted")
		#
		#world_menu.visible = true
		

func update_blocks() -> void:
	var level1_block = $Level1Block/CSGMesh3D
	
	if Global.lvl1:
		level1_block.material.albedo_color = Color(0, 1, 0)  # Green
	else:
		level1_block.material.albedo_color = Color(1, 0, 0)  # Red


#func _on_world_completions_area_body_entered(body: Node3D) -> void:
	#world_completions_label.visible = true
	#is_inside_completion_area = true
#
#
#func _on_world_completions_area_body_exited(body: Node3D) -> void:
	#world_completions_label.visible = false
	#is_inside_completion_area = false
