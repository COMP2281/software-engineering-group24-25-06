extends Node3D

@onready var SceneTransitionAnimation = $TransitionScreen/AnimationPlayer

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
		
func prepare_enter() -> void:
	$Player.show_ui()
	
func prepare_exit() -> void:
	$Player.hide_ui()
