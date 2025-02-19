extends GameSceneState

func _ready() -> void:
	SceneCoordinator.change_scene.connect(func(state: String, _metadata): finished.emit(state))

func enter(_previous_state_path: String, _data := {}) -> void:
	var battle_scene: EncounterNode = get_tree().get_first_node_in_group("encounter_group")
	battle_scene.prepare_enter()
	# Disable process mode and hide
	battle_scene.process_mode = Node.PROCESS_MODE_INHERIT
	battle_scene.show()
	
func exit() -> void:
	var battle_scene: EncounterNode = get_tree().get_first_node_in_group("encounter_group")
	battle_scene.prepare_exit()
	# Disable process mode and hide
	battle_scene.process_mode = Node.PROCESS_MODE_DISABLED
	battle_scene.hide()
