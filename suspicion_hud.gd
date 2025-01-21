extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	StealthManager.changeSusLevel.connect(updateSusLevel)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func updateSusLevel(newLevel: float) -> void:
	$ColorRect.material.set_shader_parameter("suspicion_level", newLevel);
