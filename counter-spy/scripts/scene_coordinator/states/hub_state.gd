extends GameSceneState

var child_scene: HubNode = null
@export var type : SceneType.Name = SceneType.Name.MISSION

func _ready() -> void:
	SceneCoordinator.change_scene.connect(func(state: SceneType.Name, metadata: Dictionary): finished.emit(SceneCoordinator.get_scene_name(state), metadata))
	child_scene = get_tree().get_first_node_in_group("hub_group")

func enter(_previous_state_path: String, _data := {}) -> void:
	child_scene.prepare_enter()
	_enable_processing(child_scene)
	
func exit(_data := {}) -> void:
	child_scene.prepare_exit()
	_disable_processing(child_scene)
	
