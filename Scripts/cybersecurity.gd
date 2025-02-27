extends Control

#@export var world_select_scene: PackedScene  # Exported for linking in the Inspector

func _ready():
	# Connect the back button 
	update_levels()
	
	# Connect back button signal dynamically
	$PanelContainer/MarginContainer/VBoxContainer/TitleHContainer/BackBtn.connect("pressed", Callable(self, "_on_back_btn_pressed"))

func update_levels():
	# Use the global lvl1, lvl2, etc.
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer, Global.lvl1)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer2, Global.lvl2)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer3, Global.lvl3)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer4, Global.lvl4)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer5, Global.lvl5)
	
	# Update the progress bar based on completed levels
	update_progress_bar()

func set_level_state(level_container, is_completed):
	# Get the tick and the level label nodes
	var tick = level_container.get_node("Tick")
	var level_label = level_container.get_node("Level")
	
	if is_completed:
		# If the level is completed, show the tick and restore full visibility
		tick.visible = true
		level_container.modulate = Color.from_hsv(level_container.modulate.h, level_container.modulate.s, 1.0, level_container.modulate.a)  # V = 100%
	else:
		# If the level is not completed, hide the tick and dim the container
		tick.visible = false
		level_container.modulate = Color.from_hsv(level_container.modulate.h, level_container.modulate.s, 0.5, level_container.modulate.a)  # V = 50%

func update_progress_bar():
	# Calculate the percentage of completed levels
	var completed_levels = 0
	var levels = [Global.lvl1, Global.lvl2, Global.lvl3, Global.lvl4, Global.lvl5]  # Use global variables
	var total_levels = len(levels)

	for level in levels:
		if level:
			completed_levels += 1
	
	var progress_percentage = (float(completed_levels) / float(total_levels)) * 100

	# Update the progress bar value
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MetricHBox/ProgressBar.value = progress_percentage

	# Update label
	var percentage_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MetricHBox/Label2  # Adjust path as needed
	percentage_label.text = str(progress_percentage) + "%"  # Display percentage

func _on_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world_select.tscn")
