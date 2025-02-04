extends Control

# Export variables to link scenes in the Inspector
@export var ai_scene: PackedScene
@export var cyber_security_scene: PackedScene
@export var data_analytics_scene: PackedScene
@export var main_menu_scene: PackedScene  # For the back button

var cyberscene = "res://Scenes/ProgressTracking/cyber_security.tscn"

func _ready():
	# Connect button signals using Callable
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/AI.connect("pressed", Callable(self, "_on_ai_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/CyberSecurity.connect("pressed", Callable(self, "_on_cyber_security_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/WorldHBox/DataAnalytics.connect("pressed", Callable(self, "_on_data_analytics_pressed"))
	$PanelContainer/MarginContainer/VBoxContainer/TitleHContainer/BackBtn.connect("pressed", Callable(self, "_on_back_btn_pressed"))

# Handle AI button press
func _on_ai_pressed() -> void:
	if ai_scene:
		get_tree().change_scene_to_packed(ai_scene)  # Use the PackedScene variable
	else:
		print("AI scene not linked!")

# Handle Cyber Security button press
func _on_cyber_security_pressed() -> void:
	if cyber_security_scene:
		get_tree().change_scene_to_file("res://Scenes/ProgressTracking/cyber_security.tscn")  # Use the PackedScene variable
	else:
		print("Cyber Security scene not linked!")

# Handle Data Analytics button press
func _on_data_analytics_pressed() -> void:
	if data_analytics_scene:
		get_tree().change_scene_to_packed(data_analytics_scene)  # Use the PackedScene variable
	else:
		print("Data Analytics scene not linked!")

# Handle Back button press
func _on_back_btn_pressed() -> void:
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)  # Use the PackedScene variable
	else:
		print("Main menu scene not linked!")
