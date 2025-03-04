class_name HubNode extends Node3D

func prepare_enter() -> void:
	# yikes
	$ProtoController/Head/CamYaw/CamPitch/SpringArm3D/Camera3D.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func prepare_exit() -> void:
	if $ProtoController/Head/CamYaw/CamPitch/SpringArm3D/Camera3D.current:
		$ProtoController/Head/CamYaw/CamPitch/SpringArm3D/Camera3D.clear_current(true)
