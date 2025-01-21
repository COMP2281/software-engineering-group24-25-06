extends EnemyState


func physics_update(delta:float) -> void:	
	# If we're patrolling, but the player suspicion level rises sufficiently
	if enemy.SUSPICION_LEVEL >= enemy.HUNTING_BEGIN_THRESHOLD:
		finished.emit(HUNTING)
		return 
	
	if enemy.SUSPICION_LEVEL >= enemy.INVESTIGATE_THRESHOLD:
		# Investigate the player's current position
		enemy.INVESTIGATION_POINT = get_tree().get_nodes_in_group("player")[0].global_position;
		finished.emit(INVESTIGATE)
		return 
		
	# We have some distraction/trail to investigate
	if enemy.INVESTIGATION_POINT != Vector3.INF:
		finished.emit(INVESTIGATE)
		return
	
	if not enemy.pathing_to_destination:
		var destination : Vector3;
		
		if len(enemy.PATROL_PATH) == 0:
			destination = enemy.global_position;
		else:
			destination = enemy.PATROL_PATH[enemy.current_patrol_index];
			enemy.current_patrol_index = (enemy.current_patrol_index + 1) % len(enemy.PATROL_PATH);
		
		enemy.set_destination(destination);
