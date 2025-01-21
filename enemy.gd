class_name Enemy extends CharacterBody3D;

@export_group("View zone")
## Size of view cone
@export var VIEW_RADIUS : float;
## Size of full-circle close-radius view
@export var CLOSE_RADIUS : float;
## FOV of view cone
@export_range(0.0, 2.0 * PI) var VIEW_FOV : float;

@export_group("Modifiable parameters")
@export var MOVE_SPEED : float = 5.0;
@export var HUNT_SPEED : float = 7.5;
## Time (roughly in seconds) before full detection
@export var DETECTION_SPEED : float = 1.0;
## Decay in suspicion per second (roughly)
@export var SUSPICION_DECAY_RATE : float = 0.2;
## Range in which we will care about distractions
@export var DISTRACTION_DETECTION_RANGE : float = 15.0;
## What distance can you turn in a second
@export var ROTATION_SPEED : float = PI;
## How stealthy sneaking is compared to normal walking for this enemy
@export_range(1.0, 10.0) var SNEAKING_MODIFIER : float = 2.0;

@export_group("General behaviour")
@export_range(0.0, 1.0) var SUSPICION_LEVEL : float = 0.0;
@export var CURRENTLY_SEEING_PLAYER : bool = false;

@export_group("Investigate behaviours")
## Place to investigate
@export var INVESTIGATION_POINT : Vector3 = Vector3.INF;
## At what suspicion level do we stop patrolling to investigate the player position
@export_range(0.0, 1.0) var INVESTIGATE_THRESHOLD : float = 0.4;
## How long to stay in the investigation location
@export var INVESTIGATION_TIME : float = 2.0;
## What FOV to scan during investigation
@export var FOV_SCAN : float = 0.5 * PI;
## How many times to scan area
@export var SCAN_TIMES : float = 1.5;

@export_group("Patrol behaviours")
@export var PATROL_PATH : PackedVector3Array;

@export_group("Hunt behaviours")
## At what suspicion level do we begin hunting
@export_range(0.0, 1.0) var HUNTING_BEGIN_THRESHOLD : float = 0.9;
## At what suspicion level do we give up hunting
@export_range(0.0, 1.0) var HUNTING_END_THRESHOLD : float = 0.5;

var pathing_to_destination : bool = false;
var target_angle : float = 0.0;

# Patrol variables
var current_patrol_index : int = 0;

# Investigate variables
var investigate_time_left : float = INF;

var current_speed : float

# Hunting variables
# (None)

@onready var navigation_agent_3d : NavigationAgent3D = $NavigationAgent3D;

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity");

func _ready() -> void:
	target_angle = global_rotation.y;
	current_speed = MOVE_SPEED;

# TODO: i use different math in other places for angle wrap
#	should be more consistent
# TODO: should also be "while", i just want to avoid loops
func wrap_angle(angle : float) -> float:
	if angle == INF: return INF;
	
	if angle > 1.0 * PI:
		angle -= 2.0 * PI;
	if angle < -1.0 * PI:
		angle += 2.0 * PI;
		
	return angle;

func set_heading(angle : float) -> void:
	target_angle = wrap_angle(angle);
	
func update_heading(delta : float) -> void:
	var max_change : float = ROTATION_SPEED * delta;
	var angle_diff : float = wrap_angle(target_angle - global_rotation.y);
	var direction : float = sign(angle_diff);

	global_rotation.y += direction * max_change;
	
	# Snap if close enough
	if abs(angle_diff) < max_change:
		global_rotation.y = target_angle;

func reset_investigation_params() -> void:
	investigate_time_left = INF;
	INVESTIGATION_POINT = Vector3.INF;

func set_destination(destination : Vector3) -> void:
	var closest_point : Vector3 = NavigationServer3D.map_get_closest_point(
		navigation_agent_3d.get_navigation_map(),
		destination
	);
	navigation_agent_3d.set_target_position(closest_point);
	pathing_to_destination = true;

func update_behaviour(delta: float) -> void:
	if pathing_to_destination and navigation_agent_3d.is_target_reached():
		pathing_to_destination = false;

func _process(delta: float) -> void:
	$ViewZone.VIEW_FOV = VIEW_FOV;
	$ViewZone.VIEW_RADIUS = VIEW_RADIUS;
	$ViewZone.CLOSE_RADIUS = CLOSE_RADIUS;
	$ViewZone.VIEW_DIRECTION = global_rotation.y;
	$ViewZone.EYE_LEVEL_NODE = $EyeLevel;
	
	if get_tree().get_nodes_in_group("player")[0] != null and $ViewZone.in_detection_range(get_tree().get_nodes_in_group("player")[0].global_position):
		var suspicion_delta : float = DETECTION_SPEED;

		# Be detected slower if sneaking
		if Input.is_action_pressed("sneak"):
			suspicion_delta *= 1.0 / SNEAKING_MODIFIER;
			
		SUSPICION_LEVEL += suspicion_delta * delta;
		CURRENTLY_SEEING_PLAYER = true;
	else:
		SUSPICION_LEVEL -= SUSPICION_DECAY_RATE * delta;
		CURRENTLY_SEEING_PLAYER = false;
		
	SUSPICION_LEVEL = clamp(SUSPICION_LEVEL, 0.0, 1.0);
	get_tree().get_nodes_in_group("player")[0].ENEMY_TOP_SUSPICION = max(get_tree().get_nodes_in_group("player")[0].ENEMY_TOP_SUSPICION, SUSPICION_LEVEL);
	
	if get_tree().get_nodes_in_group("player")[0].DISTRACTION != Vector3.INF and \
		global_position.distance_to(get_tree().get_nodes_in_group("player")[0].DISTRACTION) < DISTRACTION_DETECTION_RANGE:
		INVESTIGATION_POINT = get_tree().get_nodes_in_group("player")[0].DISTRACTION;
	
	update_behaviour(delta);
	update_heading(delta);
		
func _physics_process(delta: float) -> void:
	if pathing_to_destination:
		var destination : Vector3 = navigation_agent_3d.get_next_path_position();
		var local_destination : Vector3 = destination - global_position;
		var direction : Vector3 = local_destination.normalized();
		var heading : float = atan2(direction.x, direction.z) - PI;
		
		set_heading(heading);
				
		velocity.x = direction.x * current_speed;
		velocity.z = direction.z * current_speed;
	
	velocity.y += -gravity * delta;
	move_and_slide();
