extends GameSceneState

var child_scene: EncounterNode = null

func _ready() -> void:
	SceneCoordinator.change_scene.connect(func(state: String, metadata: Dictionary): finished.emit(state, metadata))
	child_scene = get_tree().get_first_node_in_group("encounter_group")

func enter(_previous_state_path: String, data := {}) -> void:
	child_scene.prepare_enter(data["enemy_encountered"])
	_enable_processing(child_scene)
	
func exit(data := {}) -> void:
	child_scene.prepare_exit()
	_disable_processing(child_scene)
	
