extends EnemyState

func enter(_previous_state_path: String, _data := {}) -> void:
	enemy.current_speed = enemy.enemy_resource.hunt_speed
	
func exit(_data := {}) -> void:
	enemy.current_speed = enemy.enemy_resource.move_speed

func physics_update(_delta: float) -> void:
	# Go back to patrol
	if enemy.suspicion_level < enemy.enemy_resource.hunting_end_threshold:
		finished.emit(PATROL)
		return
		
	# No clue where the player is, go to investigate?
	# TODO: during investigation, we suddenly gain
	#	exact knowledge of player position...
	if enemy.player_position_guess == Vector3.INF:
		finished.emit(INVESTIGATE)
		return
		
	enemy.set_destination(enemy.player_position_guess)
