class_name MissionNode extends Node3D

func prepare_enter() -> void:
	$Player.show_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func prepare_exit() -> void:
	$Player.hide_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
