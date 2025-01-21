extends EnemyState

func enter(previous_state_path: String, data := {}) -> void:
	enemy.current_speed = enemy.HUNT_SPEED

func exit():
	enemy.current_speed = enemy.MOVE_SPEED

func physics_update(delta:float) -> void:
	# Go back to patrol
	if enemy.SUSPICION_LEVEL < enemy.HUNTING_END_THRESHOLD:
		finished.emit(PATROL);
		return
	
	# Just run straight towards player
	enemy.set_destination(get_tree().get_nodes_in_group("player")[0].global_position);
