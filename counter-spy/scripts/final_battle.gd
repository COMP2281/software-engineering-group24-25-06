class_name FinalBattle extends Node3D

func prepare_enter(entered_scene) -> void:
	$Player.show_ui()
	
func prepare_exit() -> void:
	$Player.hide_ui()
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	SceneCoordinator.change_scene.emit(SceneType.Name.BATTLE, {})
