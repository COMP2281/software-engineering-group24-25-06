extends SpringArm3D

@export var MOUSE_SENSITIVITY = 0.005;
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var MIN_VERTICAL_ANGLE : float = -PI * 0.5;
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var MAX_VERTICAL_ANGLE : float = PI * 0.25;

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	
func _process(_delta : float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY;
		rotation.y = wrapf(rotation.y, 0.0, 2.0 * PI);
		rotation.x -= event.relative.y * MOUSE_SENSITIVITY;
		rotation.x = clamp(rotation.x, MIN_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE);
