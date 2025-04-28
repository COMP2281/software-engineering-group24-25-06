class_name Player extends Node3D

@export_group("Modifiable Parameters")
## The range enemies should hear the coin toss from
@export var coin_toss_range: float = 15.0
## The range enemies can hear player movement from
@export var player_movement_range: float = 2.0
@export var hacking_range: float = 25.0

const SNEAKING_SCALE: float = 0.75
const MOVEMENT_EPSILON: float = 0.5;

# TODO: rename
func hide_ui():
	$CanvasLayer.hide()
	$BonsAI.hide_ui()
	
	if $ProtoController3P.camera.current:
		$ProtoController3P.camera.clear_current(true)
	
func show_ui():
	$CanvasLayer.show()
	$BonsAI.show_ui()
	
	$ProtoController3P.camera.make_current()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta: float) -> void:
	StealthManager.player_position = $ProtoController3P.global_position
	
	# Advanced sneaking model
	if Input.is_action_pressed("sneak"):
		scale.y = SNEAKING_SCALE
	else:
		scale.y = 1.0
	
	# Hitman coin toss (TODO: just a raycast right now)
	#	create a distraction at the raycast hit location
	if Input.is_action_just_pressed("coin_toss"):
		var space_state := get_world_3d().direct_space_state
		var ray: Vector3 = -$ProtoController3P/Head/CamYaw/CamPitch/SpringArm3D.get_global_transform().basis.z
		var ray_max_extent: Vector3 = $ProtoController3P.global_position + ray * coin_toss_range
		
		var query := PhysicsRayQueryParameters3D.create($ProtoController3P.global_position, ray_max_extent, 1)
		query.collide_with_areas = true
		
		var result := space_state.intersect_ray(query)
		
		if result:
			StealthManager.player_makes_sound(result.position, coin_toss_range)
			
	# Check if facing any security cameras
	for cam in get_tree().get_nodes_in_group("security_cameras"):
		var security_camera: SecurityCamera = cam as SecurityCamera
		
		var look_dir: Vector3 = $ProtoController3P.get_look_vector()
		var camera_dir: Vector3 = (security_camera.global_position - $ProtoController3P.head.global_position)
		
		if look_dir.dot(camera_dir.normalized()) > 0.9 and camera_dir.length() < hacking_range:
			security_camera.enter_hack_range()
			
			if Input.is_action_just_pressed("interact"):
				security_camera.hack_camera()
		else:
			security_camera.exit_hack_range()
	
func _physics_process(_delta: float):
	# TODO: ignore my goofy ahh code
	global_position = $ProtoController3P.global_position
	$ProtoController3P.global_position = global_position
	
	# If the player is moving (check velocity vector if of non-zero length)
	if $ProtoController3P.velocity.length() > MOVEMENT_EPSILON:
		StealthManager.player_makes_sound($ProtoController3P.global_position, player_movement_range)
		
