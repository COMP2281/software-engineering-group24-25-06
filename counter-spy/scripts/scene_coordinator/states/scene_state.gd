class_name GameSceneState extends State

var current_data: Dictionary = {}

func _enable_processing(scene):
	scene.process_mode = Node.PROCESS_MODE_INHERIT
	scene.show()
	
func _disable_processing(scene):
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	scene.hide()
