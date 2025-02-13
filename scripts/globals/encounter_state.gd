extends GameSceneState

func _ready() -> void:
	SceneCoordinator.change_scene.connect(finished.emit)

func enter(_previous_state_path: String, _data := {}) -> void:
	var enemy_hunt_scene: Node3D = get_tree().get_nodes_in_group("battle_scene_group")[0]
	# Disable process mode and hide
	enemy_hunt_scene.process_mode = Node.PROCESS_MODE_INHERIT
	enemy_hunt_scene.show()
	
func exit() -> void:
	var enemy_hunt_scene: Node3D = get_tree().get_nodes_in_group("battle_scene_group")[0]
	# Disable process mode and hide
	enemy_hunt_scene.process_mode = Node.PROCESS_MODE_DISABLED
	enemy_hunt_scene.hide()

func physics_update(_delta: float) -> void:
	pass
