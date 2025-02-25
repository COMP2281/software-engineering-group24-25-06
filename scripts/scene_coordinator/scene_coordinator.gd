extends Node

# When changing scene, the metadata is passed both to the scene we're exiting from, and the scene
#	we're entering
signal change_scene(scene: String, metadata: Dictionary)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("change_battle"):
		change_scene.emit("Encounter", {})
	if Input.is_action_just_pressed("change_mission"):
		change_scene.emit("Mission", {})
