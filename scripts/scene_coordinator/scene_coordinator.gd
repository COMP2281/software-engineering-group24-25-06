extends Node

var current_scene: String

# Anyone should be able to check if the current scene is paused/disabled
func is_enabled(scene_name: String) -> bool:
	return scene_name == current_scene

signal change_scene(scene: String, metadata)

func _change_scene(scene: String, _metadata) -> void:
	current_scene = scene

func _ready() -> void:
	current_scene = "Mission"
	change_scene.connect(_change_scene)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("change_battle"):
		change_scene.emit("Encounter", null)
	if Input.is_action_just_pressed("change_mission"):
		change_scene.emit("Mission", null)
