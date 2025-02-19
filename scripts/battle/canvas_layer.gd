extends CanvasLayer

## TODO: REMOVE ME

func _process(delta: float) -> void:
	# TODO: this isnt running, because we stop processing this once we switch scenes
	if SceneCoordinator.is_enabled("Encounter"):
		print("Show the scene!")
		show()
	else:
		print("Hide the scene!")
		hide()
