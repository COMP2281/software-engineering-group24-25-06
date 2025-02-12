extends Node3D
func _ready() -> void:
	await get_tree().physics_frame
	hide()
