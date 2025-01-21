extends CharacterBody3D

@export_group("Modifiable Parameters")
## Player move speed
@export var MOVE_SPEED : float = 12.0;
## Maximum distraction raycast length
@export var MAX_THROW_LENGTH : float = 20.0;
## Time a distraction will persist for
@export var DISTRACTION_DURATION : float = 0.3;

var distraction_time_persisted : float = 0.0;
var yaw_input : float = 0.0;
var pitch_input : float = 0.0;

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity");

func _process(delta: float) -> void:
	if Input.is_action_pressed("sneak"):
		scale.y = 0.75;
	else:
		scale.y = 1.0;
	
	# Update how long the distraction has lasted
	distraction_time_persisted -= delta;
	distraction_time_persisted = clamp(distraction_time_persisted, 0.0, DISTRACTION_DURATION);
	
	# Delete the distraction
	if distraction_time_persisted == 0.0:
		PlayerProperties.created_distraction = Vector3.INF;
	
	# Hitman-style distraction creation
	if Input.is_action_just_pressed("coin_toss"):
		var space_state = get_world_3d().direct_space_state;
		# TODO: what did past me mean by this?
		# TODO: should probably have some lookup instead of using direct values
		var self_world = global_position;
		var ray : Vector3 = -get_global_transform().basis.z;
		var ray_world = self_world + ray * MAX_THROW_LENGTH;
		
		var query = PhysicsRayQueryParameters3D.create(self_world, ray_world, 1);
		query.collide_with_areas = true;
		
		var result = space_state.intersect_ray(query);
		
		# If raycast collided with some environment, create a distraction
		#	at that point in the environment
		if not result.is_empty():
			PlayerProperties.created_distraction = result.position;
			distraction_time_persisted = DISTRACTION_DURATION;
		
	# TODO: this should invoke some "encounter"
	# TODO: pause all movement, suspicion, etc.
	if PlayerProperties.BEING_SEEN and PlayerProperties.WITHIN_CLOSE_RADIUS and PlayerProperties.ENEMY_TOP_SUSPICION == 1.0:
		print("Caught!");
	
	# TODO: resetting the suspicion could cause issues with update order (TODO: currently causing issues)
	# PlayerProperties.ENEMY_TOP_SUSPICION = 0.0;
	PlayerProperties.BEING_SEEN = false;
	PlayerProperties.WITHIN_CLOSE_RADIUS = false;
	PlayerProperties.global_position = global_position;
	
func _physics_process(delta: float):
	var input : Vector3 = Vector3.ZERO;
	input.z = Input.get_axis("forward", "backward");
	input.x = Input.get_axis("strafe_left", "strafe_right");
	
	var dir = Vector3(input.x, 0.0, input.z).normalized();
	
	var direction : Vector3 = dir.rotated(Vector3.UP, $SpringArm3D.global_rotation.y);
	
	if is_on_floor():
		velocity.y = 0.0;
	
	velocity.z = direction.z * MOVE_SPEED;
	velocity.y += -gravity * delta;
	velocity.x = direction.x * MOVE_SPEED;
	
	move_and_slide();
