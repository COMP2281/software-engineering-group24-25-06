extends Node3D


@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var transition_screen = get_node("/root/Level1/TransitionScreen")
	transition_screen.visible = true
	var color_rect = $TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")
	await $TransitionScreen/AnimationPlayer.animation_finished
	
	transition_screen.visible = false
