class_name HubNode extends Node3D

@onready var SceneTransitionAnimation = $CanvasLayer/TransitionScreen/AnimationPlayer
@onready var transition_screen = $CanvasLayer/TransitionScreen
@onready var world_completions_label = $WorldCompletionsArea/Label3D  # Adjust the path as needed
@onready var world_menu = $CanvasLayer/WorldSelect
@onready var cyber_menu = $CanvasLayer/CyberSecurity
@onready var proto_controller: ProtoController = $Player/ProtoController3P

var is_inside_completion_area = false  # Flag to track if the player is inside the area

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var color_rect = $CanvasLayer/TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")
	await SceneTransitionAnimation.animation_finished
	
	$Player/CanvasLayer.hide()

func prepare_enter() -> void:
	$Player/ProtoController3P.camera.make_current()
	
	$CanvasLayer.show()
	$CanvasLayer/LevelSelect.hide()
	$CanvasLayer/CyberSecurity.hide()
	$CanvasLayer/WorldSelect.hide()
	proto_controller.set_all_inputs(true)
	
func prepare_exit() -> void:
	if $Player/ProtoController3P.camera.current:
		$Player/ProtoController3P.camera.clear_current(true)
		
	$CanvasLayer.hide()
