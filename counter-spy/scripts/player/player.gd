class_name Player extends Node3D

@export_group("Modifiable Parameters")
## The range enemies should hear the coin toss from
@export var coin_toss_range: float = 35.0
## The range enemies can hear player movement from
@export var player_movement_range: float = 5.0

const MOVEMENT_EPSILON: float = 0.1;
const SNEAKING_SCALE: float = 0.75

# TODO: rename
# TODO: should pass in camera from scene probably
func hide_ui():
	$SuspicionView.hide()
	$AlertIndicator.hide()
	
	if $ProtoController3P.camera.current:
		$ProtoController3P.camera.clear_current(true)
	
func show_ui():
	$SuspicionView.show()
	$AlertIndicator.show()
	$ProtoController3P.camera.make_current()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(_delta: float) -> void:
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
	
func _physics_process(_delta: float):
	# If the player is moving (check velocity vector if of non-zero length)
	if $ProtoController3P.get_real_velocity().length() > MOVEMENT_EPSILON:
		StealthManager.player_makes_sound($ProtoController3P.global_position, player_movement_range)
