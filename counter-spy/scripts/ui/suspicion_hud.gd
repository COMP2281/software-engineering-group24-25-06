extends Control

func _ready() -> void:
	StealthManager.change_suspicion_level.connect(update_suspicion_level)

func update_suspicion_level(new_level: float) -> void:
	print("Suspicion level updated!")
	$ColorRect.material.set_shader_parameter("suspicion_level", new_level)
