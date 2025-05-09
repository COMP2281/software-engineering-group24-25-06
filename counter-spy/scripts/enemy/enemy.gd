class_name Enemy extends CharacterBody3D

@export_group("Enemy properties")
@export var enemy_resource: EnemyResource
@export var enemy_level_id: int

@export_group("Patrol behaviours")
## The path about which this unit patrols
@export var patrol_path: Path3D

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
	current_speed = enemy_resource.move_speed
	$Security.viewzone_resource = enemy_resource.viewzone_resource
	$Security.new_distraction.connect(update_distraction_point)
	# NOTE: we want the suspicion level from our view zone,
	#	not the global suspicion level from the stealth manager
	$Security.new_suspicion_level.connect(update_suspicion_level)
	
func die() -> void:
	remove_child(self)
	self.queue_free()
	
	# TODO: hacky fix, but set all suspicion levels to 0
	StealthManager.set_all_suspicion_level.emit(0.0)

func update_distraction_point(location: Vector3) -> void:
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
	
	# TODO: better system
	#	currently just tries to path to 0,0 immediately
	if closest_point == Vector3.ZERO:
		navigation_agent_3d.set_target_position(global_position)
		return
	
	navigation_agent_3d.set_target_position(closest_point)

func _process(delta: float) -> void:
	$Security.eye_level_position = $EyeLevel.global_position
	
	var max_change: float = enemy_resource.max_rotation_speed * delta
	var angle_diff: float = angle_difference(global_rotation.y, target_angle)
	var direction: float = sign(angle_diff)
	
	global_rotation.y += direction * min(max_change, abs(angle_diff))
	
	player_position_guess = $Security.guess_player_position()
	
	# Check if we should begin battle
	var player_distance: float = (StealthManager.player_position - global_position).length()
	
	if StealthManager.can_be_seen \
		and currently_seeing_player \
		and player_distance < enemy_resource.battle_begin_proximity \
		and suspicion_level > 0.95:
		# TODO: reset all suspicion levels
		# TODO: grace period sent to player
		SceneCoordinator.change_scene.emit(SceneType.Name.BATTLE, {"enemy_encountered": self})
	
func _physics_process(delta: float) -> void:
	var direction: Vector3 = Vector3.ZERO
	var heading: float = target_angle
	
	if not navigation_agent_3d.is_navigation_finished():
		var destination: Vector3 = navigation_agent_3d.get_next_path_position()
		var local_destination: Vector3 = destination - global_position
		direction = local_destination.normalized()
		heading = atan2(direction.x, direction.z) - PI
	
		set_heading(heading)
		
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
