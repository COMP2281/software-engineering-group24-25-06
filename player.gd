extends CharacterBody3D

@export_group("Modifiable Parameters")
## Player move speed
@export var MOVE_SPEED : float = 12.0;
## Camera sensitivity
@export var MOUSE_SENSITIVITY : float = 0.001;
## Range (radians) in which you can look down
@export var DOWN_RANGE : float = 0.3;
## Range (radians) in which you can look up
@export var UP_RANGE : float = 0.3;
## Maximum distraction raycast length
@export var MAX_THROW_LENGTH : float = 20.0;
## Time a distraction will persist for
@export var DISTRACTION_DURATION : float = 0.3;

@export_group("Script interoperability")
## Track the top suspicion level of this update
@export var ENEMY_TOP_SUSPICION : float = 0.0;
## Where to create a distraction for enemies
@export var DISTRACTION : Vector3 = Vector3.INF;

var distraction_time_persisted = 0.0;
var yaw_input = 0.0;
var pitch_input = 0.0;

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

@onready var camera_node := $YawCameraPivot/PitchCameraPivot/SpringArm3D/Camera3D;
@onready var pitch_pivot := $YawCameraPivot/PitchCameraPivot;
@onready var yaw_pivot := $YawCameraPivot;

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
		
	if Input.is_action_pressed("sneak"):
		scale.y = 0.75;
	else:
		scale.y = 1.0;
		
	distraction_time_persisted -= delta;
	distraction_time_persisted = clamp(distraction_time_persisted, 0.0, DISTRACTION_DURATION);
	
	if distraction_time_persisted == 0.0:
		DISTRACTION = Vector3.INF;
	
	if Input.is_action_just_pressed("coin_toss"):
		var space_state = get_world_3d().direct_space_state;
		# TODO: should probably have some lookup instead of using direct values
		var self_world = global_position;
		var ray : Vector3 = -camera_node.get_global_transform().basis.z;
		var ray_world = self_world + ray * MAX_THROW_LENGTH;
		
		var query = PhysicsRayQueryParameters3D.create(self_world, ray_world, 1);
		query.collide_with_areas = true;
		
		var result = space_state.intersect_ray(query);
		
		if not result.is_empty():
			DISTRACTION = result.position;
			distraction_time_persisted = DISTRACTION_DURATION;
		
	yaw_pivot.rotate_y(yaw_input);
	pitch_pivot.rotate_x(pitch_input);
	
	# Clamp both directions
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		-DOWN_RANGE * PI,
		UP_RANGE * PI
	);
	
	yaw_input = 0.0;
	pitch_input = 0.0;
	
	$SuspicionView.SUSPICION_LEVEL = ENEMY_TOP_SUSPICION;
	ENEMY_TOP_SUSPICION = 0.0;
	
func _physics_process(delta: float):
	var input : Vector3 = Vector3.ZERO;
	input.z = Input.get_axis("forward", "backward");
	input.x = Input.get_axis("strafe_left", "strafe_right");
	
	var dir = (yaw_pivot.transform.basis * input).normalized();
	
	velocity.z = dir.z * MOVE_SPEED;
	velocity.y += -gravity * delta;
	velocity.x = dir.x * MOVE_SPEED;
	move_and_slide();

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			yaw_input = -event.relative.x * MOUSE_SENSITIVITY;
			pitch_input = -event.relative.y * MOUSE_SENSITIVITY;
