extends CharacterBody3D

const SPEED = 12
const JUMP_VELOCITY = 10.0
const CAMERA_ROTATE_SPEED = 2.0  # Degrees per second

func _ready() -> void:
	$Camera_controller.rotation_degrees = Vector3.ZERO
	$MeshInstance3D.rotation_degrees = Vector3.ZERO
 	
func _physics_process(delta: float) -> void:
	# Smooth camera rotation while holding cam_left or cam_right
	if Input.is_action_pressed("cam_left"):
		$Camera_controller.rotate_y(deg_to_rad(CAMERA_ROTATE_SPEED * delta * 60))  # Rotate left
	if Input.is_action_pressed("cam_right"):
		$Camera_controller.rotate_y(deg_to_rad(-CAMERA_ROTATE_SPEED * delta * 60))  # Rotate right

	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction: Vector3 = ($Camera_controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Rotate the MeshInstance3D based on input direction
	if input_dir != Vector2(0, 0):
		$MeshInstance3D.rotation_degrees.y = $Camera_controller.rotation_degrees.y - rad_to_deg(input_dir.angle()) - 90

	# Apply velocity based on movement direction
	if direction.length() > 0.0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	# Apply movement
	move_and_slide()

	# Add camera smoothing
	%Camera_controller.global_position = lerp($Camera_controller.global_position, global_position, delta * 10)


func _on_area_3d_body_entered(body: Node3D) -> void:
	get_tree().change_scene_to_file("res://gui/level_select_screen.tscn")
