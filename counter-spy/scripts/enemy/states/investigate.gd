extends EnemyState

# TODO: fix this brutalised code

var time_spent_getting_to_location: float = 0.0
var investigate_time_left: float = 0.0

func enter(_previous_state_path: String, _data := {}) -> void:
	# If there is no new investigation point, go to patrol
	if enemy.new_investigation_point == Vector3.INF:
		finished.emit(PATROL)
		return
		
	# Otherwise, path to the investigation point
	enemy.set_destination(enemy.new_investigation_point)
	enemy.new_investigation_point = Vector3.INF
	investigate_time_left = 2.0

func exit(_data := {}) -> void:
	investigate_time_left = 0.0
	time_spent_getting_to_location = 0.0

func physics_update(delta: float) -> void:
	if enemy.suspicion_level > enemy.enemy_resource.hunting_begin_threshold:
		finished.emit(HUNTING)
		return
		
	if investigate_time_left <= 0.0:
		finished.emit(PATROL)
		return
	
	# Check if we've arrived at the location
	if enemy.navigation_agent_3d.is_target_reached():
		time_spent_getting_to_location = 0.0
		# Reset velocity so we don't just glide in the same direction
		enemy.velocity.x = 0.0
		enemy.velocity.z = 0.0
		
		investigate_time_left = clamp(investigate_time_left - delta, 0.0, 2.0)
		
		# If we see player during investigation, try to follow them with the camera
		if enemy.currently_seeing_player:
			var towards_player: Vector3 = (StealthManager.player_position - enemy.global_position).normalized()
			var toward_player_angle: float = atan2(towards_player.x, towards_player.z) - PI
			enemy.set_heading(toward_player_angle)
		# Otherwise scan around the location to look for them
		else:
			# Scan around the place
			var percent_time_spent: float = 1.0 - investigate_time_left / 2.0
			var direction: float = sign(sin(percent_time_spent * 2.0 * PI * 2.0))
			var speed: float = (0.5 * PI * 2.0) / 2.0
			
			enemy.set_heading(enemy.global_rotation.y + direction * speed * delta)
