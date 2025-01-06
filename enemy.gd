extends CharacterBody3D;

@export var player_node : Node3D = null;

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

@export_group("General behaviour")
@export_range(0.0, 1.0) var SUSPICION_LEVEL : float = 0.0;
@export var CURRENTLY_SEEING_PLAYER : bool = false;

@export_group("Investigate behaviours")
## Place to investigate
@export var INVESTIGATION_POINT : Vector3 = Vector3.INF;
## At what suspicion level do we stop patrolling to investigate the player position
@export_range(0.0, 1.0) var INVESTIGATE_THRESHOLD : float = 0.2;
# TODO: currently includes moving time, shouldn't!
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

enum Behaviour { PATROL, INVESTIGATE, HUNTING };

var current_behaviour = Behaviour.PATROL;
var pathing_to_destination : bool = false;

# Patrol variables
var current_patrol_index : int = 0;

# Investigate variables
var investigate_position : Vector3 = Vector3.INF;
var investigate_time_left : float = INF;

# Hunting variables

@onready var navigation_agent_3d : NavigationAgent3D = $NavigationAgent3D;

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ViewZone.VIEW_FOV = VIEW_FOV;
	$ViewZone.VIEW_RADIUS = VIEW_RADIUS;
	$ViewZone.CLOSE_RADIUS = CLOSE_RADIUS;

func behaviour_patrol(delta: float) -> void:
	current_behaviour = Behaviour.PATROL;
	reset_investigation_params();
	
	# If we're patrolling, but the player suspicion level rises sufficiently
	if SUSPICION_LEVEL >= HUNTING_BEGIN_THRESHOLD:
		return behaviour_hunting(delta);
	
	if SUSPICION_LEVEL >= INVESTIGATE_THRESHOLD:
		# Investigate the player's current position
		investigate_position = player_node.global_position;
		
		return behaviour_investigate(delta);
		
	# We have some distraction/trail to investigate
	if INVESTIGATION_POINT != Vector3.INF:
		investigate_position = INVESTIGATION_POINT;
		
		return behaviour_investigate(delta);
	
	if not pathing_to_destination and len(PATROL_PATH) > 0:
		var destination : Vector3 = PATROL_PATH[current_patrol_index];
		
		current_patrol_index = (current_patrol_index + 1) % len(PATROL_PATH);
		
		set_destination(destination);
	
func behaviour_investigate(delta: float) -> void:
	current_behaviour = Behaviour.INVESTIGATE;
	
	if SUSPICION_LEVEL > HUNTING_BEGIN_THRESHOLD:
		return behaviour_hunting(delta);
	
	if investigate_position == Vector3.INF:
		return behaviour_patrol(delta);
		
	if investigate_time_left == INF:
		investigate_time_left = INVESTIGATION_TIME;
	
	# Check if we've arrived at the location
	if navigation_agent_3d.is_target_reached():
		# Reset velocity so we don't just glide in the same direction
		velocity.x = 0.0;
		velocity.z = 0.0;
		
		INVESTIGATION_POINT = Vector3.INF;
		investigate_time_left = clamp(investigate_time_left - delta, 0.0, INVESTIGATION_TIME);
		
		# Go back to patrol
		if investigate_time_left == 0.0:
			return behaviour_patrol(delta);
	
		# Scan around the place?
		# Value from 0-1
		var percent_time_spent = 1.0 - investigate_time_left / INVESTIGATION_TIME;
		var direction = sign(sin(percent_time_spent * 2.0 * PI * SCAN_TIMES));
		var speed = (FOV_SCAN * SCAN_TIMES) / INVESTIGATION_TIME;
		
		global_rotation.y += direction * speed * delta;
	else:
		set_destination(investigate_position);
	
func behaviour_hunting(delta: float) -> void:
	current_behaviour = Behaviour.HUNTING;
	reset_investigation_params();
	
	# Go back to patrol
	if SUSPICION_LEVEL < HUNTING_END_THRESHOLD:
		return behaviour_patrol(delta);
		
	# Just run straight towards player
	set_destination(player_node.global_position);
	
func reset_investigation_params() -> void:
	investigate_time_left = INF;
	investigate_position = Vector3.INF;

func set_destination(destination : Vector3) -> void:
	var closest_point : Vector3 = NavigationServer3D.map_get_closest_point(
		navigation_agent_3d.get_navigation_map(),
		destination
	);
	navigation_agent_3d.set_target_position(closest_point);
	pathing_to_destination = true;

func update_behaviour(delta: float) -> void:
	match current_behaviour:
		Behaviour.PATROL:
			behaviour_patrol(delta);
		Behaviour.INVESTIGATE:
			behaviour_investigate(delta);
		Behaviour.HUNTING:
			behaviour_hunting(delta);
			
	if pathing_to_destination and navigation_agent_3d.is_target_reached():
		pathing_to_destination = false;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$ViewZone.VIEW_DIRECTION = global_rotation.y;
	
	if player_node != null and $ViewZone.in_detection_range(player_node.global_position):
		var suspicion_delta : float = DETECTION_SPEED;

		# Be detected twice as slow if sneaking
		if Input.is_action_pressed("sneak"):
			suspicion_delta *= 0.5;
			
		SUSPICION_LEVEL += suspicion_delta * delta;
		CURRENTLY_SEEING_PLAYER = true;
	else:
		SUSPICION_LEVEL -= SUSPICION_DECAY_RATE * delta;
		CURRENTLY_SEEING_PLAYER = false;
		
	SUSPICION_LEVEL = clamp(SUSPICION_LEVEL, 0.0, 1.0);
	player_node.ENEMY_TOP_SUSPICION = max(player_node.ENEMY_TOP_SUSPICION, SUSPICION_LEVEL);
	
	# TODO: range check?
	if player_node.DISTRACTION != Vector3.INF:
		INVESTIGATION_POINT = player_node.DISTRACTION;
		
	update_behaviour(delta);
		
func _physics_process(delta: float) -> void:
	if pathing_to_destination:
		var destination : Vector3 = navigation_agent_3d.get_next_path_position();
		var local_destination : Vector3 = destination - global_position;
		var direction : Vector3 = local_destination.normalized();
		var heading : float = atan2(direction.x, direction.z);
		
		global_rotation.y = heading - PI;
		
		var current_speed : float = HUNT_SPEED if current_behaviour == Behaviour.HUNTING else MOVE_SPEED;
		
		velocity.x = direction.x * current_speed;
		velocity.z = direction.z * current_speed;
	
	velocity.y += -gravity * delta;
	move_and_slide();
