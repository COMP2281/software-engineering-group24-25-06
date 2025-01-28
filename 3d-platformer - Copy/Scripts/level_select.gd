extends Control

var is_in_area = false

func _ready():
	$AnimationPlayer.play('RESET')
	self.visible = false
	
	# Connect the signals for the area3d
	var area = get_node_or_null("/root/Hub/LevelSelectArea")
	if area:
		area.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
		area.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
	else:
		print("Error: Area3D not found in the scene.")


func close_levels():
	$AnimationPlayer.play_backwards('load_select_level')
	self.visible = false
	
func open_levels():
	$AnimationPlayer.play('load_select_level')
	self.visible = true
	
func on_interact():
	if is_in_area:
		if Input.is_action_just_pressed('Interact'):
			if self.visible == false:
				open_levels()
			else:
				close_levels()

func _on_back_btn_pressed() -> void:
	close_levels()

func _on_level_1_pressed() -> void:
	get_tree().change_scene_to_file('res://Scenes/level_1.tscn')

func _process(delta):
	on_interact()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Steve":  # Replace "Player" with the name of your player node
		print("Player entered the area.")
		is_in_area = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "Steve":  # Replace "Player" with the name of your player node
		print("Player exited the area.")
		is_in_area = false
