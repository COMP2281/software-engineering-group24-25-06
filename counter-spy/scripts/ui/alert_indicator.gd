extends Control

func _ready() -> void:
	StealthManager.change_global_alertness.connect(update_global_alertness)

func update_global_alertness(new_level: float) -> void:
	$ColorRect.material.set_shader_parameter("alertness_level", new_level)
