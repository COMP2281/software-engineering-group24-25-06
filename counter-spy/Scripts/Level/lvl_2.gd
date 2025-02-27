extends Node3D


@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var color_rect = $TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
