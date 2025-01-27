class_name Enemy extends CharacterBody3D;

@export_group("View zone")
## Size of view cone
@export var VIEW_RADIUS : float = 15;
## Size of full-circle close-radius view
@export var CLOSE_RADIUS : float = 2;
## FOV of view cone
@export_range(0.0, 2.0 * PI) var VIEW_FOV : float = .8;

@export_group("Behaviour Properties")
@export_subgroup("Movement")
@export var MOVE_SPEED : float = 5.0;
@export var HUNT_SPEED : float = 7.5;
## What distance can you turn in a second
@export var ROTATION_SPEED : float = PI;
@export_subgroup("Detection")
## Time (roughly in seconds) before full detection
@export var DETECTION_SPEED : float = 1.0;
## Decay in suspicion per second (roughly)
@export var SUSPICION_DECAY_RATE : float = 0.2;
## Range in which we will care about distractions
@export var DISTRACTION_DETECTION_RANGE : float = 15.0;
## How stealthy sneaking is compared to normal walking for this enemy
@export_range(1.0, 10.0) var SNEAKING_MODIFIER : float = 2.0;

# NOTE: Maybe we can remove some of this? Seems like excessive customisation, setting investigation time and scan speed will inherently set scan times and fov scan... idk...
@export_group("Investigate behaviours")
## At what suspicion level do we stop patrolling to investigate the player position
@export_range(0.0, 1.0) var INVESTIGATE_THRESHOLD : float = 0.4;
## How long to stay in the investigation location
@export var INVESTIGATION_TIME : float = 2.0;
## What FOV to scan during investigation
@export var FOV_SCAN : float = 0.5 * PI;
## How many times to scan area
@export var SCAN_TIMES : float = 1.5;

@export var PATROL_PATH : Path3D;

## At what suspicion level do we begin hunting
@export_range(0.0, 1.0) var HUNTING_BEGIN_THRESHOLD : float = 0.9;
## At what suspicion level do we give up hunting
@export_range(0.0, 1.0) var HUNTING_END_THRESHOLD : float = 0.5;

@onready var navigation_agent_3d : NavigationAgent3D = $NavigationAgent3D;

var current_speed : float
## Place to investigate
var new_INVESTIGATION_POINT : Vector3;
var target_angle : float = 0.0;
var SUSPICION_LEVEL : float = 0.0;
var CURRENTLY_SEEING_PLAYER : bool = false;

var investigate_time_left : float = INF;

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

func set_destination(destination : Vector3) -> void:
	# Ensure we're not attempting to recalculate our path every frame
	#	add a short cooldown period between updates
	if pathing_time <= NAVIGATION_RECALCULATE_COOLDOWN: return;
	
	var closest_point : Vector3 = NavigationServer3D.map_get_closest_point(
		navigation_agent_3d.get_navigation_map(),
		destination
	);
	navigation_agent_3d.set_target_position(closest_point);

func _process(delta: float) -> void:
	calculate_stealth_modifier(delta);
	
	$ViewZone.viewzone_resource = viewzone_resource;
	$ViewZone.VIEW_DIRECTION = global_rotation.y;
	$ViewZone.EYE_LEVEL_NODE = $EyeLevel;

	var detection_manifold : DetectionManifold = $ViewZone.in_detection_range(PlayerProperties.global_position);
	
	if get_tree().get_nodes_in_group("player")[0] != null and $ViewZone.in_detection_range(get_tree().get_nodes_in_group("player")[0].global_position):
		var suspicion_delta : float = DETECTION_SPEED;
			
		suspicion_delta *= 1.0 / stealth_modifier;
			
		SUSPICION_LEVEL += suspicion_delta * delta;
		CURRENTLY_SEEING_PLAYER = true;
	else:
		SUSPICION_LEVEL -= SUSPICION_DECAY_RATE * delta;
		CURRENTLY_SEEING_PLAYER = false;
		
	SUSPICION_LEVEL = clamp(SUSPICION_LEVEL, 0.0, 1.0);

	if get_tree().get_nodes_in_group("player")[0].DISTRACTION != Vector3.INF and \
		global_position.distance_to(get_tree().get_nodes_in_group("player")[0].DISTRACTION) < DISTRACTION_DETECTION_RANGE:
		new_INVESTIGATION_POINT = get_tree().get_nodes_in_group("player")[0].DISTRACTION;
	
	rotate_y(sign(wrap_angle(target_angle - global_rotation.y)) * min(abs(wrap_angle(target_angle - global_rotation.y)), ROTATION_SPEED * delta))

func _physics_process(delta: float) -> void:
	var destination : Vector3 = navigation_agent_3d.get_next_path_position();
	var local_destination : Vector3 = destination - global_position;
	var direction : Vector3 = local_destination.normalized();
	var heading : float = atan2(direction.x, direction.z) - PI;
	
	set_heading(heading);
	velocity = direction * Vector3(1,0,1) * current_speed;
	
	# Add the gravity -> from default template
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide();
