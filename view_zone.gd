extends Node3D

@export var CLOSE_RADIUS : float;
@export var VIEW_RADIUS : float;
@export var VIEW_FOV : float;
@export var VIEW_DIRECTION : float = 0.0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$VisualMesh3D.set_instance_shader_parameter("view_direction", VIEW_DIRECTION);
	$VisualMesh3D.set_instance_shader_parameter("view_radius", VIEW_RADIUS);
	$VisualMesh3D.set_instance_shader_parameter("view_fov", VIEW_FOV);
	$VisualMesh3D.set_instance_shader_parameter("close_radius", CLOSE_RADIUS);
	$VisualMesh3D.set_instance_shader_parameter("quad_size", $VisualMesh3D.mesh.size.x);

func in_detection_range(position : Vector3) -> bool:
	# TODO: check math
	# TODO: might need to pass the global position
	var distance : float = (Vector2(global_position.x, global_position.z) - Vector2(position.x, position.z)).length();
	
	if (distance < CLOSE_RADIUS): return true;
	
	var origin_angle = -0.5 * PI;
	var angle : float = -(atan2(position.z - global_position.z, position.x - global_position.x) - origin_angle);
	var relative_direction_angle = PI - abs(fmod(abs(angle - VIEW_DIRECTION), 2.0 * PI) - PI);
	
	if (relative_direction_angle > VIEW_FOV or distance > VIEW_RADIUS): return false;
	
	var space_state = get_world_3d().direct_space_state;
	# TODO: need to exclude ourselfs with collision mask
	var query = PhysicsRayQueryParameters3D.create(global_position, position, 1);
	query.collide_with_areas = true;
	
	var result = space_state.intersect_ray(query);
	
	if result.is_empty(): return true;
	
	return false;
