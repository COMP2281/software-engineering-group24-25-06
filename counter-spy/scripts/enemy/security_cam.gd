class_name SecurityCamera extends Node3D

@export var viewzone_resource: ViewzoneResource

func _ready() -> void:
	$Security.viewzone_resource = viewzone_resource

func _process(_delta: float) -> void:
	$Security.eye_level_position = global_position
