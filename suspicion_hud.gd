extends Control

@export var SUSPICION_LEVEL : float = 0.0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$ColorRect.material.set_shader_parameter("suspicion_level", SUSPICION_LEVEL);
