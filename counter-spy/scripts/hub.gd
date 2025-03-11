class_name HubNode extends Node3D

@onready var SceneTransitionAnimation = $CanvasLayer/TransitionScreen/AnimationPlayer
@onready var transition_screen = $CanvasLayer/TransitionScreen
@onready var world_completions_label = $WorldCompletionsArea/Label3D  # Adjust the path as needed
@onready var world_menu = $CanvasLayer/WorldSelect
@onready var cyber_menu = $CanvasLayer/CyberSecurity

var is_inside_completion_area = false  # Flag to track if the player is inside the area

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var color_rect = $CanvasLayer/TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")
	await SceneTransitionAnimation.animation_finished

func prepare_enter() -> void:
	$Player/ProtoController3P.camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	$CanvasLayer.show()
	
func prepare_exit() -> void:
	if $Player/ProtoController3P.camera.current:
		$Player/ProtoController3P.camera.clear_current(true)
		
	$CanvasLayer.hide()
