class_name SecurityCamera extends Node3D

@export var viewzone_resource: ViewzoneResource
@export var disabled_text: String = "Disabled"
@export var waiting_text: String = "[E] Interact to hack!"
@export var disable_time: float = 5.0

var disabled_elapsed: float = 0.0

func _ready() -> void:
	$Security.viewzone_resource = viewzone_resource

func _process(delta: float) -> void:
	$Security.eye_level_position = global_position
	disabled_elapsed += delta
	
	if disabled_elapsed > disable_time:
		$HackText.text = waiting_text
		$Security.visible = true
		$Security.enabled = true

func enter_hack_range() -> void:
	$HackText.visible = true
	
func exit_hack_range() -> void:
	$HackText.visible = false

func hack_camera() -> void:
	$HackText.text = disabled_text
	$HackText.visible = false
	$Security.visible = false
	$Security.enabled = false
	disabled_elapsed = 0.0
	
	print("Changing scene!")
	SceneCoordinator.change_scene.emit(SceneType.Name.MINIGAME, {})
