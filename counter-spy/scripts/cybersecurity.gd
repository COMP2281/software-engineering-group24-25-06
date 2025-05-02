extends Control

# Called when the node enters the scene tree
func _ready():
	# Update all level states and progress bar on start
	update_levels()
	
	# Connect the Back button to its callback function
	$PanelContainer/MarginContainer/VBoxContainer/TitleHContainer/BackBtn.connect("pressed", Callable(self, "_on_back_btn_pressed"))

# Updates each level's appearance based on its completion state
func update_levels():
	# Set state for each level using global completion flags
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer, Global.lvl1)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer2, Global.lvl2)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer3, Global.lvl3)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer4, Global.lvl4)
	set_level_state($PanelContainer/MarginContainer/VBoxContainer/LevelsHBox/PanelContainer5, Global.lvl5)
	
	# Refresh progress bar after setting level states
	update_progress_bar()

# Sets the visual state of an individual level panel
func set_level_state(level_container, is_completed):
	# Retrieve the tick icon and level label within the container
	var tick = level_container.get_node("Tick")
	var level_label = level_container.get_node("Level")
	
	if is_completed:
		# Show the tick and brighten the level container
		tick.visible = true
		level_container.modulate = Color.from_hsv(
			level_container.modulate.h,
			level_container.modulate.s,
			1.0,  # Full brightness (Value)
			level_container.modulate.a
		)
	else:
		# Hide the tick and dim the level container
		tick.visible = false
		level_container.modulate = Color.from_hsv(
			level_container.modulate.h,
			level_container.modulate.s,
			0.5,  # 50% brightness
			level_container.modulate.a
		)

# Updates the progress bar and label based on completed levels
func update_progress_bar():
	var completed_levels = 0
	var levels = [Global.lvl1, Global.lvl2, Global.lvl3, Global.lvl4, Global.lvl5]
	var total_levels = len(levels)

	# Count how many levels are marked completed
	for level in levels:
		if level:
			completed_levels += 1
	
	# Compute completion percentage
	var progress_percentage = (float(completed_levels) / float(total_levels)) * 100

	# Set progress bar value
	$PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MetricHBox/ProgressBar.value = progress_percentage

	# Update the percentage label text
	var percentage_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MetricHBox/Label2
	percentage_label.text = str(progress_percentage) + "%"

# Called when the back button is pressed
func _on_back_btn_pressed() -> void:
	# Hide the CyberSecurity menu (this current node)
	$".".visible = false

	# Show the WorldSelect screen again
	$"../WorldSelect".visible = true
