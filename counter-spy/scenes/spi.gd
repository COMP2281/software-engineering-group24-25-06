extends Node3D

@export var proto_controller: ProtoController

@export var movement_epsilon = 0.1;

func _process(_delta: float) -> void:
	if proto_controller and proto_controller.velocity.length() > movement_epsilon:
		$AnimationPlayer.play("spiAnims/Spi_run")
	else:
		$AnimationPlayer.play("spiAnims/Spi_idle")
