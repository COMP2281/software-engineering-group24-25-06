extends Node

# When changing scene, the metadata is passed both to the scene we're exiting from, and the scene
#	we're entering
signal change_scene(scene: SceneType.Name, metadata: Dictionary)

# TODO: the lengths to get a global enum...
@export var type : SceneType.Name = SceneType.Name.MISSION

func _ready() -> void:
	change_scene.connect(log_scene_change)

func get_scene_name(scene: SceneType.Name) -> String:
	match scene:
		SceneType.Name.MISSION: return "Mission"
		SceneType.Name.BATTLE: return "Encounter"
		SceneType.Name.HUB: return "Hub"
		SceneType.Name.MINIGAME: return "Minigame"
	
	return "Unknown"
	
func get_scene_enum(scene: String) -> SceneType.Name:
	match scene:
		"Mission": return SceneType.Name.MISSION
		"Encounter": return SceneType.Name.BATTLE
		"Hub": return SceneType.Name.HUB
		"Minigame": return SceneType.Name.MINIGAME
		
	# Default to mission scene
	return SceneType.Name.MISSION

func log_scene_change(scene: SceneType.Name, _metadata: Dictionary) -> void:
	print("Scene transition to ", scene, " named ", get_scene_name(scene))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("change_battle"):
		change_scene.emit(SceneType.Name.BATTLE, {})
	if Input.is_action_just_pressed("change_mission"):
		change_scene.emit(SceneType.Name.MISSION, { "deload_level": true, "level_name": "res://scenes/levels/mission1/level_1.tscn" })
	if Input.is_action_just_pressed("change_hub"):
		change_scene.emit(SceneType.Name.HUB, {})
