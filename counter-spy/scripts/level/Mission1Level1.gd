extends Node3D

@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer
@onready var LevelCompleteLabel = $Area3D/LevelCompleteLabel
@onready var transition_screen = $TransitionScreen

var inside_area: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var transition_screen = $TransitionScreen
	transition_screen.visible = true
	var color_rect = $TransitionScreen/ColorRect  # Adjust path as needed
	color_rect.color = Color(0, 0, 0, 1)  # Fully opaque black
	SceneTransitionAnimation.play("fade_out_to_level")
	await $TransitionScreen/AnimationPlayer.animation_finished
	transition_screen.visible = false
	
	var level_metadata: LevelMetadata = LevelMetadataLoader.load_level_metadata("res://settings/level/level1.json")
	
	# TODO: technically unnecessary, we can set properties in the editor to be the same
	#	as the level description
	for enemy_node in get_tree().get_nodes_in_group("enemy"):
		var id = str(enemy_node.enemy_level_id)
		enemy_node.enemy_resource.enemy_name = level_metadata.enemies_by_id[id].name
		enemy_node.enemy_resource.weakness = level_metadata.enemies_by_id[id].weakness

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if inside_area and Input.is_action_just_pressed("interact"):
		# Change the lvl1 value in the Global singleton
		Global.lvl1 = true
		Global.save_game()  # Save the updated value permanently
		
		print("lvl1 is now: ", Global.lvl1)
		# Scene transition
		transition_screen.visible = true
		SceneTransitionAnimation.play("fade_in_to_loading_screen")
		await $TransitionScreen/AnimationPlayer.animation_finished
		
		get_tree().change_scene_to_file("res://scenes/hub.tscn")

func prepare_enter() -> void:
	$Player.show_ui()
	
func prepare_exit() -> void:
	$Player.hide_ui()
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	inside_area = true
	LevelCompleteLabel.visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	inside_area = true
	LevelCompleteLabel.visible = true
