class_name GameSceneState extends State

# TODO: if/when bothered, convert to enums?
var MISSION: String = "Mission"
var ENCOUNTER: String = "Encounter"
var current_data: Dictionary = {}

func _enable_processing(scene: Node3D):
	scene.process_mode = Node.PROCESS_MODE_INHERIT
	scene.show()
	
func _disable_processing(scene: Node3D):
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.hide()
