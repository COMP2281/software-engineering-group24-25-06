extends Node

# TODO: the lengths to get a global enum...
@export var type : SceneType.Name = SceneType.Name.MISSION

func get_scene_name(scene: SceneType.Name) -> String:
	match scene:
		SceneType.Name.MISSION: return "Mission"
		SceneType.Name.BATTLE: return "Encounter"
		SceneType.Name.HUB: return "Hub"
	
	return "Unknown"
	
func get_scene_enum(scene: String) -> SceneType.Name:
	match scene:
		"Mission": return SceneType.Name.MISSION
		"Encounter": return SceneType.Name.BATTLE
		"Hub": return SceneType.Name.HUB
		
	# Default to mission scene
	return SceneType.Name.MISSION

# When changing scene, the metadata is passed both to the scene we're exiting from, and the scene
#	we're entering
signal change_scene(scene: SceneType.Name, metadata: Dictionary)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("change_battle"):
		change_scene.emit(SceneType.Name.BATTLE, {})
	if Input.is_action_just_pressed("change_mission"):
		change_scene.emit(SceneType.Name.MISSION, {})
