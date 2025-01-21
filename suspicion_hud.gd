extends Control

func _process(_delta: float) -> void:
	$ColorRect.material.set_shader_parameter("suspicion_level", PlayerProperties.ENEMY_TOP_SUSPICION);
