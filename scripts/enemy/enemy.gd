class_name Enemy extends CharacterBody3D

@export_group("View zone")
## Resource containing detection properties
@export var viewzone_resource: ViewzoneResource

@export_group("Behaviour Properties")
@export_subgroup("Movement")
@export var move_speed: float = 5.0
@export var hunt_speed: float = 7.5
## What distance can you turn in a second
@export var max_rotation_speed: float = PI

@export_group("Investigate behaviours")
## At what suspicion level do we stop patrolling to investigate the player position
@export_range(0.0, 1.0) var investigate_begin_threshold: float = 0.4
## How long to stay in the investigation location
@export var investigation_time: float = 2.0
## What FOV to scan during investigation
@export_range(0.0, 360.0, 0.5, "radians_as_degrees") var fov_scan: float = 0.5 * PI
# NOTE: unless we have a desired rotation speed (max_rotation_speed? although that might be too fast)
#	it is necessary to have all these properties (i think) - not necessary to have them all customisable
#	of course
## How many times to scan in the location
@export var scan_times: float = 1.5

@export_group("Patrol behaviours")
## The path about which this unit patrols
@export var patrol_path: Path3D

@export_group("Hunting behaviours")
## At what suspicion level do we begin hunting
@export_range(0.0, 1.0) var hunting_begin_threshold: float = 0.9
## At what suspicion level do we give up hunting
@export_range(0.0, 1.0) var hunting_end_threshold: float = 0.5

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

var current_speed: float
var new_investigation_point: Vector3
var target_angle: float = 0.0
var suspicion_level: float = 0.0
var currently_seeing_player: bool = false
var investigate_time_left: float = INF
# The enemies best guess on the player's position
var player_position_guess: Vector3 = Vector3.INF

func _ready() -> void:
	target_angle = global_rotation.y
	current_speed = move_speed
	$ViewZone.viewzone_resource = viewzone_resource
	$ViewZone.new_distraction.connect(process_distraction)
	# NOTE: we want the suspicion level from our view zone,
	#	not the global suspicion level from the stealth manager
	$ViewZone.new_suspicion_level.connect(update_suspicion_level)

func process_distraction(location: Vector3) -> void:
	new_investigation_point = location
	
func update_suspicion_level(new_suspicion: float, seeing_player: bool) -> void:
	suspicion_level = new_suspicion
	currently_seeing_player = seeing_player

func set_heading(angle: float) -> void:
	target_angle = wrapf(angle, -1.0 * PI, 1.0 * PI)

func set_destination(destination: Vector3) -> void:
	if destination == Vector3.INF: return
	
	# TODO: also ignore call if made before first map synchronisation
	
	var closest_point: Vector3 = NavigationServer3D.map_get_closest_point(
		navigation_agent_3d.get_navigation_map(),
		destination
	)
	navigation_agent_3d.set_target_position(closest_point)

func _process(delta: float) -> void:
	$ViewZone.view_direction = global_rotation.y
	$ViewZone.eye_level_position = $EyeLevel.global_position
	
	var max_change: float = max_rotation_speed * delta
	var angle_diff: float = wrapf(target_angle - global_rotation.y, -1.0 * PI, 1.0 * PI)
	var direction: float = sign(angle_diff)
	
	global_rotation.y += direction * min(max_change, abs(angle_diff))
	
	player_position_guess = $ViewZone.guess_player_position()
	
func _physics_process(delta: float) -> void:
	var destination: Vector3 = navigation_agent_3d.get_next_path_position()
	var local_destination: Vector3 = destination - global_position
	var direction: Vector3 = local_destination.normalized()
	var heading: float = atan2(direction.x, direction.z) - PI
	
	set_heading(heading)
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
