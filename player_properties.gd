extends Node;

# TODO: consistent naming convention of these globals
var ENEMY_TOP_SUSPICION : float = 0.0;
var BEING_SEEN : bool = false;
var WITHIN_CLOSE_RADIUS : bool = false;
var created_distraction : Vector3 = Vector3.INF;
var global_position : Vector3 = Vector3.ZERO;

func reset() -> void:
	ENEMY_TOP_SUSPICION = 0.0;
	BEING_SEEN = false;
	WITHIN_CLOSE_RADIUS = false;
	created_distraction = Vector3.INF;
