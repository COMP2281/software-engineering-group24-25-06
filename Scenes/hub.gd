extends Node3D

@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer
@onready var transition_screen = get_node("/root/Hub/TransitionScreen")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	transition_screen.visible = true
	update_blocks()
	var color_rect = $TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")
	await SceneTransitionAnimation.animation_finished
	
	transition_screen.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_blocks() -> void:
	var level1_block = $Level1Block/CSGMesh3D
	
	if Global.lvl1:
		level1_block.material.albedo_color = Color(0, 1, 0)  # Green
	else:
		level1_block.material.albedo_color = Color(1, 0, 0)  # Red
