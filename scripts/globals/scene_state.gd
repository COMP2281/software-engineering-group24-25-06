class_name GameSceneState extends State

# TODO: if/when bothered, convert to enums?
var MISSION: String = "Mission"
var ENCOUNTER: String = "Encounter"

func enter(_previous_state_path: String, _data := {}) -> void:
	# TODO: undisable mission scene (get by group)
	pass
	
func exit() -> void:
	# TODO: disable mission scene (get by group)
	pass

func physics_update(_delta: float) -> void:
	pass
