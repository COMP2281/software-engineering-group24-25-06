extends EnemyState

func enter(previous_state_path: String, data := {}) -> void:
	if not enemy.new_INVESTIGATION_POINT:
		finished.emit(PATROL)
		return
	enemy.set_destination(enemy.new_INVESTIGATION_POINT);
	enemy.new_INVESTIGATION_POINT = Vector3.ZERO
	enemy.investigate_time_left = enemy.INVESTIGATION_TIME;

func physics_update(delta:float) -> void:
	if enemy.SUSPICION_LEVEL > enemy.HUNTING_BEGIN_THRESHOLD:
		finished.emit(HUNTING);
		return
	
	if enemy.investigate_time_left <= 0:
		finished.emit(PATROL);
		return 
	
	# Check if we've arrived at the location
	if enemy.navigation_agent_3d.is_target_reached():
		# Reset velocity so we don't just glide in the same direction
		enemy.velocity.x = 0.0;
		enemy.velocity.z = 0.0;
		
		# Begin decreasing the investigation time
		enemy.investigate_time_left = clamp(enemy.investigate_time_left - delta, 0.0, enemy.INVESTIGATION_TIME);
	
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
