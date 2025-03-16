extends Node3D

func _process(_delta: float) -> void:
	if Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		$AnimationPlayer.play("spiAnims/Spi_run")
	else:
		$AnimationPlayer.play("spiAnims/Spi_idle")
