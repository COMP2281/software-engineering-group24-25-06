extends GameSceneState

var child_scene: EncounterNode = null
@export var type : SceneType.Name = SceneType.Name.MISSION

func _ready() -> void:
	SceneCoordinator.change_scene.connect(func(state: SceneType.Name, metadata: Dictionary): finished.emit(SceneCoordinator.get_scene_name(state), metadata))
	child_scene = get_tree().get_first_node_in_group("encounter_group")

func enter(previous_state_path: String, data := {}) -> void:
	if SceneCoordinator.get_scene_enum(previous_state_path) == SceneType.Name.MISSION:
		child_scene.entered_from_mission(data)
	if SceneCoordinator.get_scene_enum(previous_state_path) == SceneType.Name.FINAL_BATTLE:
		child_scene.entered_from_final_battle()
	
	child_scene.prepare_enter()
	_enable_processing(child_scene)
	
func exit(_data := {}) -> void:
	child_scene.prepare_exit()
	_disable_processing(child_scene)
	
