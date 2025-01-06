extends CharacterBody3D

@export var MOVE_SPEED : float = 12.0;
@export var MOUSE_SENSITIVITY : float = 0.001;
@export var YAW_INPUT : float = 0.0;
@export var PITCH_INPUT : float = 0.0;
@export var DOWN_RANGE : float = 0.1;
@export var UP_RANGE : float = 0.3;
@export var MAX_THROW_LENGTH : float = 20.0;
# Track the top suspicion level of this update
@export var ENEMY_TOP_SUSPICION : float = 0.0;
@export var DISTRACTION : Vector3 = Vector3.INF;
@export var DISTRACTION_DURATION : float = 0.3;

var distraction_time_persisted = 0.0;

var ORIGIN_PITCH : float = 0.0;

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity");

@onready var CAMERA_NODE := $YawCameraPivot/PitchCameraPivot/SpringArm3D/Camera3D;
@onready var PITCH_PIVOT := $YawCameraPivot/PitchCameraPivot;
@onready var YAW_PIVOT := $YawCameraPivot;

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	ORIGIN_PITCH = CAMERA_NODE.rotation.x;

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
		var ray : Vector3 = -CAMERA_NODE.get_global_transform().basis.z;
		var ray_world = self_world + ray * MAX_THROW_LENGTH;
		
		var query = PhysicsRayQueryParameters3D.create(self_world, ray_world, 1);
		query.collide_with_areas = true;
		
		var result = space_state.intersect_ray(query);
		
		if not result.is_empty():
			DISTRACTION = result.position;
			distraction_time_persisted = DISTRACTION_DURATION;
		
	YAW_PIVOT.rotate_y(YAW_INPUT);
	PITCH_PIVOT.rotate_x(PITCH_INPUT);
	
	# Clamp both directions
	PITCH_PIVOT.rotation.x = clamp(
		PITCH_PIVOT.rotation.x,
		-DOWN_RANGE * PI + ORIGIN_PITCH,
		UP_RANGE * PI + ORIGIN_PITCH
	);
	
	YAW_INPUT = 0.0;
	PITCH_INPUT = 0.0;
	
	$SuspicionView.SUSPICION_LEVEL = ENEMY_TOP_SUSPICION;
	ENEMY_TOP_SUSPICION = 0.0;
	
func _physics_process(delta: float):
	var input : Vector3 = Vector3.ZERO;
	input.z = Input.get_axis("forward", "backward");
	input.x = Input.get_axis("strafe_left", "strafe_right");
	
	var dir = (YAW_PIVOT.transform.basis * input).normalized();
	
	velocity.z = dir.z * MOVE_SPEED;
	velocity.y += -gravity * delta;
	velocity.x = dir.x * MOVE_SPEED;
	move_and_slide();

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			YAW_INPUT = -event.relative.x * MOUSE_SENSITIVITY;
			PITCH_INPUT = -event.relative.y * MOUSE_SENSITIVITY;
