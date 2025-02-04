extends Node3D

@export var CLOSE_RADIUS : float;
@export var VIEW_RADIUS : float;
@export var VIEW_FOV : float;
@export var VIEW_DIRECTION : float = 0.0;

@export var EYE_LEVEL_NODE : Node3D;

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
	
	$VisualMesh3D.mesh.size = Vector2(VIEW_RADIUS, VIEW_RADIUS) * 2.0;

func in_detection_range(position : Vector3) -> bool:
	# TODO: check math
	var distance : float = (Vector2(global_position.x, global_position.z) - Vector2(position.x, position.z)).length();
	
	# If they're within the close radius
	if (distance < CLOSE_RADIUS): return true;
	
	var origin_angle = -0.5 * PI;
	var angle : float = -(atan2(position.z - global_position.z, position.x - global_position.x) - origin_angle);
	var relative_direction_angle = PI - abs(fmod(abs(angle - VIEW_DIRECTION), 2.0 * PI) - PI);
	
	# If they're within our FOV and distance
	if (relative_direction_angle > VIEW_FOV or distance > VIEW_RADIUS): return false;
	
	var space_state = get_world_3d().direct_space_state;
	var query = PhysicsRayQueryParameters3D.create(EYE_LEVEL_NODE.global_position, position, 1);
	query.collide_with_areas = true;
	
	var result = space_state.intersect_ray(query);
	
	# If the raycast found nothing
	return result.is_empty();
