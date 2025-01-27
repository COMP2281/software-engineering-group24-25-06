extends CharacterBody3D

@export_group("Modifiable Parameters")
## Player move speed
@export var move_speed: float = 12.0
## Maximum distraction raycast length
@export var max_throw_length: float = 20.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var spring_arm := $SpringArm3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	StealthManager.player_position = global_position
	
	# Advanced sneaking model
	if Input.is_action_pressed("sneak"):
		scale.y = 0.75
	else:
		scale.y = 1.0
	
	# Hitman coin toss (TODO: just a raycast right now)
	#	create a distraction at the raycast hit location
	if Input.is_action_just_pressed("coin_toss"):
		var space_state := get_world_3d().direct_space_state
		# TODO: should probably have some lookup instead of using direct values
		var self_world: Vector3 = global_position
		var ray: Vector3 = -spring_arm.get_global_transform().basis.z
		var ray_world: Vector3 = self_world + ray * max_throw_length
		
		var query := PhysicsRayQueryParameters3D.create(self_world, ray_world, 1)
		query.collide_with_areas = true
		
		var result := space_state.intersect_ray(query)
		
		if not result:
			StealthManager.create_distraction(result.position)
	
func _physics_process(delta: float):
	var input: Vector3 = Vector3.ZERO
	input.z = Input.get_axis("forward", "backward")
	input.x = Input.get_axis("strafe_left", "strafe_right")
	
	var direction: Vector3 = (spring_arm.transform.basis * input).normalized()
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if not is_on_floor():
		velocity.y += -gravity * delta
		
	move_and_slide()
