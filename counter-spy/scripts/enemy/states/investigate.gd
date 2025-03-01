extends EnemyState

func enter(_previous_state_path: String, _data := {}) -> void:
	# If there is no new investigation point, go to patrol
	if enemy.new_investigation_point == Vector3.INF:
		finished.emit(PATROL)
		return
		
	# Otherwise, path to the investigation point
	enemy.set_destination(enemy.new_investigation_point)
	enemy.new_investigation_point = Vector3.INF
	enemy.investigate_time_left = enemy.enemy_resource.investigation_time

func physics_update(delta: float) -> void:
	if enemy.suspicion_level > enemy.enemy_resource.hunting_begin_threshold:
		finished.emit(HUNTING)
		return
	
	if enemy.investigate_time_left <= 0.0:
		finished.emit(PATROL)
		return
		
	if enemy.new_investigation_point != Vector3.INF:
		enemy.set_destination(enemy.new_investigation_point)
		enemy.new_investigation_point = Vector3.INF
		enemy.investigate_time_left = enemy.enemy_resource.investigation_time
	
	# Check if we've arrived at the location
	if enemy.navigation_agent_3d.is_target_reached():
		# Reset velocity so we don't just glide in the same direction
		enemy.velocity.x = 0.0
		enemy.velocity.z = 0.0
		
		# Begin decreasing the investigation time
		enemy.investigate_time_left = clamp(enemy.investigate_time_left - delta, 0.0, enemy.enemy_resource.investigation_time)
	
		# If we see player during investigation, try to follow them with the camera
		if enemy.currently_seeing_player:
			var towards_player: Vector3 = (StealthManager.player_position - enemy.global_position).normalized()
			var toward_player_angle: float = atan2(towards_player.x, towards_player.z) - PI
			enemy.set_heading(toward_player_angle)
		# Otherwise scan around the location to look for them
		else:
			# Scan around the place
			var percent_time_spent: float = 1.0 - enemy.investigate_time_left / enemy.enemy_resource.investigation_time
			var direction: float = sign(sin(percent_time_spent * 2.0 * PI * enemy.enemy_resource.scan_times))
			var speed: float = (enemy.enemy_resource.fov_scan * enemy.enemy_resource.scan_times) / enemy.enemy_resource.investigation_time
			
			enemy.set_heading(enemy.global_rotation.y + direction * speed * delta)
