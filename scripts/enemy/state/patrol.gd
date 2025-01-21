extends EnemyState

# Patrol variables
var current_patrol_offset : float = 0;

func find_closest_abs_pos(path: Path3D,global_pos: Vector3):
	# https://medium.com/@oddlyshapeddog/finding-the-nearest-global-position-on-a-curve-in-godot-4-726d0c23defb
	var curve: Curve3D = path.curve
	  # transform the target position to local space
	var path_transform: Transform3D = path.global_transform
	var local_pos: Vector3 = global_pos * path_transform
	  # get the nearest offset on the curve
	var offset: float = curve.get_closest_offset(local_pos)
	  # get the local position at this offset
	var curve_pos: Vector3 = curve.sample_baked(offset, true)
	  # transform it back to world space
	curve_pos = path_transform * curve_pos
	return curve_pos

func enter(previous_state_path: String, data := {}) -> void:
	if not enemy.PATROL_PATH: return
	enemy.PATROL_PATH.get_child(0).progress = enemy.PATROL_PATH.curve.get_closest_offset(enemy.global_position)
	if previous_state_path == "":
		enemy.global_position = enemy.PATROL_PATH.get_child(0).global_position * Vector3(1,0,1) + enemy.global_position * Vector3(0,1,0)
		await get_tree().physics_frame
	enemy.set_destination(enemy.PATROL_PATH.get_child(0).global_position)

func physics_update(delta:float) -> void:
	# If we're patrolling, but the player suspicion level rises sufficiently
	if enemy.SUSPICION_LEVEL >= enemy.HUNTING_BEGIN_THRESHOLD:
		finished.emit(HUNTING)
		return
	
	if enemy.SUSPICION_LEVEL >= enemy.INVESTIGATE_THRESHOLD:
		# Investigate the player's current position
		enemy.new_INVESTIGATION_POINT = get_tree().get_nodes_in_group("player")[0].global_position;
		finished.emit(INVESTIGATE)
		return
		
	# We have some distraction/trail to investigate
	if enemy.new_INVESTIGATION_POINT:
		finished.emit(INVESTIGATE)
		return

	if not enemy.PATROL_PATH: return
	if enemy.navigation_agent_3d.distance_to_target() < 2:
		enemy.PATROL_PATH.get_child(0).progress += enemy.current_speed * delta * 2
		enemy.set_destination(enemy.PATROL_PATH.get_child(0).global_position);
