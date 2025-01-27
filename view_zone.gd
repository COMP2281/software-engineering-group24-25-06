extends Node3D

@export_category("Modifiable Parameters")
@export var viewzone_resource : Resource;
@export var EYE_LEVEL_NODE : Node3D;

@export_category("Script interoperability")
@export var VIEW_DIRECTION : float = 0.0;

# TODO: should move detection stuff here maybe?

func _process(_delta: float) -> void:
	$VisualMesh3D.set_instance_shader_parameter("view_radius", viewzone_resource.view_radius);
	$VisualMesh3D.set_instance_shader_parameter("view_fov", viewzone_resource.fov);
	$VisualMesh3D.set_instance_shader_parameter("close_radius", viewzone_resource.close_radius);
	$VisualMesh3D.set_instance_shader_parameter("quad_size", $VisualMesh3D.mesh.size.x);
	
	$VisualMesh3D.mesh.size = Vector2(viewzone_resource.view_radius, viewzone_resource.view_radius) * 2.0;

func in_detection_range(player_position : Vector3) -> DetectionManifold:
	var manifold : DetectionManifold = DetectionManifold.new();
	manifold.distance = (Vector2(global_position.x, global_position.z) - Vector2(player_position.x, player_position.z)).length();
	manifold.being_seen = false;
	manifold.within_close_range = false;
	
	# If they're within the close radius
	if manifold.distance < viewzone_resource.close_radius:
		manifold.being_seen = true;
		manifold.within_close_range = true;
		
		return manifold;
	
	# Calculate angle relative to the centerline of the view cone
	var origin_angle : float = -0.5 * PI;
	var angle : float = -(atan2(player_position.z - global_position.z, player_position.x - global_position.x) - origin_angle);
	# TODO: better comparison?
	var relative_direction_angle : float = PI - abs(fmod(abs(angle - VIEW_DIRECTION), 2.0 * PI) - PI);
	
	# If they're not within our FOV or our view radius, early return
	if relative_direction_angle > viewzone_resource.fov or manifold.distance > viewzone_resource.view_radius:
		return manifold;
	
	# Send a raycast to see if there's something blocking our view of the player
	var space_state := get_world_3d().direct_space_state;
	var query := PhysicsRayQueryParameters3D.create(EYE_LEVEL_NODE.global_position, player_position, 1);
	query.collide_with_areas = true;
	
	var result := space_state.intersect_ray(query);
	
	# If the raycast collided with nothing
	if result.is_empty(): manifold.being_seen = true;
	
	return manifold;
