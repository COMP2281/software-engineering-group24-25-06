extends GameSceneState

func _ready() -> void:
	SceneCoordinator.change_scene.connect(func(state: String, _metadata): finished.emit(state))

func enter(_previous_state_path: String, _data := {}) -> void:
	var enemy_hunt_scene: MissionNode = get_tree().get_first_node_in_group("mission_group")
	enemy_hunt_scene.prepare_enter()
	# Disable process mode and hide
	enemy_hunt_scene.process_mode = Node.PROCESS_MODE_INHERIT
	enemy_hunt_scene.show()
	
func exit() -> void:
	var enemy_hunt_scene: MissionNode = get_tree().get_first_node_in_group("mission_group")
	enemy_hunt_scene.prepare_exit()
	# Disable process mode and hide
	enemy_hunt_scene.process_mode = Node.PROCESS_MODE_DISABLED
	enemy_hunt_scene.hide()
