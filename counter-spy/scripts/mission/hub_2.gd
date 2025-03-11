class_name HubNode extends Node3D

func prepare_enter() -> void:
	$ProtoController.camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func prepare_exit() -> void:
	if $ProtoController.camera.current:
		$ProtoController.camera.clear_current(true)
		
	$LevelSelect.hide()
