extends EnemyState

# Patrol variables
var current_patrol_offset : float = 0

func find_closest_abs_pos(path: Path3D, global_pos: Vector3):
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

func enter(previous_state_path: String, _data := {}) -> void:
	if not enemy.patrol_path: return
	enemy.patrol_path.get_child(0).progress = enemy.patrol_path.curve.get_closest_offset(enemy.global_position)
	
	if previous_state_path == "":
		enemy.global_position = enemy.patrol_path.get_child(0).global_position * Vector3(1.0, 0.0, 1.0) + enemy.global_position * Vector3(0.0, 1.0, 0.0)
		await get_tree().physics_frame
	
	enemy.set_destination(enemy.patrol_path.get_child(0).global_position)

func physics_update(delta: float) -> void:
	# If we're patrolling, but the player suspicion level rises sufficiently
	if enemy.suspicion_level >= enemy.enemy_resource.hunting_begin_threshold:
		finished.emit(HUNTING)
		return
	
	# If we receive knowledge of player whereabouts
	#	raise suspicion
	#	go to investigate player
	if enemy.player_position_guess != Vector3.INF:
		# If we are already suspicious of the player
		#	let this enemy join in on the search
		if StealthManager.suspicion_level > enemy.enemy_resource.investigate_begin_threshold:
			enemy.suspicion_level = max(enemy.enemy_resource.investigate_begin_threshold, enemy.suspicion_level)
			enemy.new_investigation_point = enemy.player_position_guess
			
			finished.emit(INVESTIGATE)
			return
	
	if enemy.suspicion_level >= enemy.enemy_resource.investigate_begin_threshold:
		# Investigate the player's current position
		#	TODO: maybe go to last observation instead?
		enemy.new_investigation_point = StealthManager.player_position
		finished.emit(INVESTIGATE)
		return
		
	# We have some distraction/trail to investigate
	if enemy.new_investigation_point:
		finished.emit(INVESTIGATE)
		return

	# If we don't have a patrol path, don't calculate it
	if not enemy.patrol_path: return

	if enemy.navigation_agent_3d.distance_to_target() < 2.0:
		enemy.patrol_path.get_child(0).progress += enemy.current_speed * delta * 2
		enemy.set_destination(enemy.patrol_path.get_child(0).global_position)
