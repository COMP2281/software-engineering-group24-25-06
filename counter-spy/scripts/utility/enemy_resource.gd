class_name EnemyResource extends Resource

@export var viewzone_resource: ViewzoneResource = null

@export_group("Generic")
@export var enemy_name: String

@export_group("Battle properties")
@export_range(10, 500) var health: int = 100
#TODO: should be enum, store enums in global script?
@export var weakness: String = "fire"

@export_group("Behaviour Properties")
@export var battle_begin_proximity: float = 3.0

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

@export_group("Hunting behaviours")
## At what suspicion level do we begin hunting
@export_range(0.0, 1.0) var hunting_begin_threshold: float = 0.9
## At what suspicion level do we give up hunting
@export_range(0.0, 1.0) var hunting_end_threshold: float = 0.5
