extends EnemyState

func physics_update(delta:float) -> void:	
	if enemy.SUSPICION_LEVEL > enemy.HUNTING_BEGIN_THRESHOLD:
		enemy.reset_investigation_params();
		finished.emit(HUNTING);
		return
	
	if enemy.INVESTIGATION_POINT != Vector3.INF:
		enemy.set_destination(enemy.INVESTIGATION_POINT);
		enemy.INVESTIGATION_POINT = Vector3.INF;
		enemy.investigate_time_left = enemy.INVESTIGATION_TIME;
	
	if enemy.investigate_time_left == 0.0:
		enemy.reset_investigation_params();
		finished.emit(PATROL);
		return 
	
	# Check if we've arrived at the location
	if enemy.navigation_agent_3d.is_target_reached():
		# Reset velocity so we don't just glide in the same direction
		enemy.velocity.x = 0.0;
		enemy.velocity.z = 0.0;
		
		# Begin decreasing the investigation time
		enemy.investigate_time_left = clamp(enemy.investigate_time_left - delta, 0.0, enemy.INVESTIGATION_TIME);
		
		# Go back to patrol
		if enemy.investigate_time_left == 0.0:
			enemy.reset_investigation_params();
			finished.emit(PATROL);
			return 
	
		# If we see player during investigation, try to follow them with the camera
		if enemy.CURRENTLY_SEEING_PLAYER:
			var towards_player : Vector3 = (get_tree().get_nodes_in_group("player")[0].global_position - enemy.global_position).normalized();
			var toward_player_angle : float = atan2(towards_player.x, towards_player.z) - PI;
			enemy.set_heading(toward_player_angle);
		# Otherwise scan around the location to look for them
		else:
			# Scan around the place
			var percent_time_spent : float = 1.0 - enemy.investigate_time_left / enemy.INVESTIGATION_TIME;
			var direction : float = sign(sin(percent_time_spent * 2.0 * PI * enemy.SCAN_TIMES));
			var speed : float = (enemy.FOV_SCAN * enemy.SCAN_TIMES) / enemy.INVESTIGATION_TIME;
			
			enemy.set_heading(enemy.target_angle + direction * speed * delta);
