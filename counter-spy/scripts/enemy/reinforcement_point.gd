class_name ReinforcementPoint extends Node3D

var has_activated = false

func _ready() -> void:
	$Enemy.visible = false
	$Enemy.process_mode = Node.PROCESS_MODE_DISABLED
	
func activate() -> void:
	if has_activated: return
	
	$Enemy.visible = true
	$Enemy.process_mode = Node.PROCESS_MODE_INHERIT
	
	has_activated = true
