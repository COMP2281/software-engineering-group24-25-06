extends GameSceneState

var child_scene: MissionNode = null
@export var type : SceneType.Name = SceneType.Name.MISSION

func _ready() -> void:
	SceneCoordinator.change_scene.connect(func(state: SceneType.Name, metadata: Dictionary): finished.emit(SceneCoordinator.get_scene_name(state), metadata))
	child_scene = get_tree().get_first_node_in_group("mission_group")
	
func enter(previous_state_path: String, data := {}) -> void:
	# TODO: terrible code, data should also provide the level to load
	if data != {}:
		print("Attempting to load level with data: ", data)
		
		if data["deload_level"] == true:
			child_scene.deload_level()
		
		if data["level_name"]:
			child_scene.load_level(data["level_name"])
	else:
		push_error("No data passed to level loader!")
		
	# We expect the data passed to contain the "enemy_defeated field"
	# TODO: maybe dedicated structures for EncounterToMission (etc.)
	if SceneCoordinator.get_scene_enum(previous_state_path) == SceneType.Name.BATTLE:
		child_scene.entered_from_encounter(data)
	
	child_scene.prepare_enter()
	_enable_processing(child_scene)
	
func exit(_data := {}) -> void:
	child_scene.prepare_exit()
	_disable_processing(child_scene)
	
