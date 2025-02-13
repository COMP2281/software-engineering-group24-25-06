# TODO: ViewZone has grown way too large
#	properly just rename to something more generic
#	or split up the scene to separate rendering
#	and suspicion calculations
class_name ViewZone extends Node3D

const OBSERVATION_EXPIRY: float = 1.0
const OMNIPOTENCE_DURATION: float = 0.5

var viewzone_resource: ViewzoneResource = null

var view_direction: float = 0.0
var eye_level_position: Vector3

var view_radius: float = INF
var view_fov: float = 0.0
var close_radius: float = 0.0
var detection_speed: float = 0.0
var heard_sound_vector: Vector2 = Vector2(0.0, 0.0)
var heard_sound_elapsed: float = 0.0

var suspicion_level: float = 0.0
var currently_seeing_player: bool = false
var time_since_seen_player: float = INF

signal new_distraction(location: Vector3)
signal new_suspicion_level(suspicion_level: float, seeing_player: bool)

func update_properties(stealth_modifier: float):
	if viewzone_resource == null: return
	
	var multiplier: float = 1.0 / stealth_modifier
	
	close_radius = viewzone_resource.close_radius
	view_radius = viewzone_resource.view_radius * multiplier
	view_fov = viewzone_resource.fov * multiplier
	detection_speed = viewzone_resource.detection_speed * multiplier
	
	$VisualMesh3D.mesh.size = Vector2(view_radius, view_radius) * 2.0
	$VisualMesh3D.set_instance_shader_parameter("view_radius", view_radius)
	$VisualMesh3D.set_instance_shader_parameter("view_fov", view_fov)
	$VisualMesh3D.set_instance_shader_parameter("close_radius", close_radius)
	$VisualMesh3D.set_instance_shader_parameter("sound_instance_vector", heard_sound_vector)
	$VisualMesh3D.set_instance_shader_parameter("quad_size", $VisualMesh3D.mesh.size.x)
	
func _ready() -> void:
	StealthManager.change_stealth_level.connect(update_properties)

func _process(delta: float) -> void:
	# TODO: better way to do this? _ready seems to be running in a different order
	#	manually update properties
	if viewzone_resource == null: return
	
	if view_radius == INF:
		update_properties(1.0)
	
	# Set the view direction each frame since it likely changes every frame
	$VisualMesh3D.set_instance_shader_parameter("view_direction", view_direction)
	
	var detection_manifold: DetectionManifold = in_detection_range(StealthManager.player_position)
	
	currently_seeing_player = detection_manifold.being_seen
	
	if detection_manifold.being_seen:
		suspicion_level += 1.0 / detection_speed * delta
		StealthManager.observe_player(StealthManager.player_position, global_position)
		time_since_seen_player = 0.0
	else:
		suspicion_level -= viewzone_resource.decay_rate * delta
		time_since_seen_player += delta
		
	suspicion_level = clamp(suspicion_level, 0.0, 1.0)
	
	heard_sound_elapsed += delta
	
	if heard_sound_elapsed > 1.0:
		heard_sound_vector = Vector2.ZERO
	
	# TODO: emit event only on change
	new_suspicion_level.emit(suspicion_level, detection_manifold.being_seen)

func in_detection_range(player_position: Vector3) -> DetectionManifold:
	var manifold: DetectionManifold = DetectionManifold.new()
	manifold.distance = (Vector2(global_position.x, global_position.z) - Vector2(player_position.x, player_position.z)).length()
	manifold.being_seen = false
	manifold.within_close_range = false
	
	# If they're within the close radius
	if manifold.distance < close_radius:
		manifold.being_seen = true
		manifold.within_close_range = true
		
		return manifold
	
	# Calculate angle relative to the centerline of the view cone
	var origin_angle: float = -0.5 * PI
	var angle: float = -(atan2(player_position.z - global_position.z, player_position.x - global_position.x) - origin_angle)
	# TODO: better comparison?
	var relative_direction_angle: float = PI - abs(fmod(abs(angle - view_direction), 2.0 * PI) - PI)
	
	# If they're not within our FOV or our view radius, early return
	if relative_direction_angle > view_fov or manifold.distance > view_radius:
		return manifold
	
	# Send a raycast to see if there's something blocking our view of the player
	var space_state := get_world_3d().direct_space_state
	# TODO: read some proper value for the mask ("1"), instead of magic number
	var query := PhysicsRayQueryParameters3D.create(eye_level_position, player_position, 1)
	query.collide_with_areas = true
	
	var result := space_state.intersect_ray(query)
	
	# If the raycast collided with nothing
	if result.is_empty(): manifold.being_seen = true
	
	return manifold
	
func process_distraction(location: Vector3, hearing_range: float) -> void:
	if viewzone_resource.hearing_modifier == 0.0: return
	
	var heard_sound_vector3: Vector3 = location - global_position
	heard_sound_vector = Vector2(heard_sound_vector3.x, heard_sound_vector3.z)
	
	var dist: float = global_position.distance_to(location)
	if dist < hearing_range * viewzone_resource.hearing_modifier / StealthManager.stealth_modifier:
		new_distraction.emit(location)
		
func guess_player_position() -> Vector3:
	if currently_seeing_player:
		return StealthManager.player_position
	
	# If we last saw the player recently, have omnipotence on the player's
	#	location
	if time_since_seen_player < OMNIPOTENCE_DURATION:
		return StealthManager.player_position
	
	# Ensure the observation is adequately recent
	if StealthManager.player_observed_elapsed > OBSERVATION_EXPIRY:
		# We have no good guess
		return Vector3.INF
		
	# Calculate distance to last observee
	if global_position.distance_to(StealthManager.player_observer_position) >= viewzone_resource.communication_range:
		return Vector3.INF
	
	# Observation is a decent guess
	return StealthManager.player_observed_position
