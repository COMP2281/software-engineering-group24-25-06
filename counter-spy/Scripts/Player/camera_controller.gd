extends Node3D

signal set_cam_rotation(_cam_rotation : float)
@export var player : ProtoController
@onready var yaw_node = $CamYaw
@onready var pitch_node = $CamYaw/CamPitch
@onready var spring_arm = $CamYaw/CamPitch/SpringArm3D
@onready var camera = $CamYaw/CamPitch/SpringArm3D/Camera3D
var yaw : float = 0
var pitch : float = 0
var yaw_sensitivity : float = 0.07
var pitch_sensitivity : float = 0.07
var yaw_acceleration : float = 15
var pitch_acceleration : float = 15
var pitch_max : float = 20
var pitch_min : float = -60
var tween : Tween
var position_offset : Vector3 = Vector3(0, 1.3, 0)
var position_offset_target : Vector3 = Vector3(0, 1.3, 0)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spring_arm.add_excluded_object(player.get_rid())
	top_level = true


func _input(event):
	if event is InputEventMouseMotion and player.can_move:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += event.relative.y * pitch_sensitivity


func _physics_process(delta):
	position_offset = lerp(position_offset, position_offset_target, 4 * delta)
	global_position = lerp(global_position, player.global_position + position_offset, 18 * delta)
	
	pitch = clamp(pitch, pitch_min, pitch_max)
	
	#yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	#pitch_node.rotation_degrees.x = lerp(pitch_node.rotation_degrees.x, pitch, pitch_acceleration * delta)
	
	#if you don't want to lerp, set them directly
	yaw_node.rotation_degrees.y = yaw
	player.rotation_degrees.y = yaw
	pitch_node.rotation_degrees.x = pitch
	
	#set_cam_rotation.emit(yaw_node.rotation.y)
