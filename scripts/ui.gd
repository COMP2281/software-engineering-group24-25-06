extends Control

@onready var success_label = $Successrate

func _ready():
	anchors_preset = Control.PRESET_FULL_RECT
	
	style_health_bar($Playerhealth, true)
	
	style_health_bar($Enemyhealth, false)
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_health_bar_positions()
	setup_success_label()
	get_node("../..").success_rate_change.connect(_on_success_rate_changed)


func style_health_bar(bar, is_player):
	var style = StyleBoxFlat.new()
	var bg_style = StyleBoxFlat.new()
	
	if is_player:
		style.bg_color = Color("#3498DB")  
		style.border_color = Color("#2980B9")
		bg_style.bg_color = Color("#2980B9").darkened(0.5)
	else:
		style.bg_color = Color("#E74C3C") 
		style.border_color = Color("#C0392B")
		bg_style.bg_color = Color("#C0392B").darkened(0.5)
	
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	
	bar.add_theme_stylebox_override("fill", style)
	bar.add_theme_stylebox_override("background", bg_style)

func _update_health_bar_positions():
	var screen_width = get_viewport().size.x
	$Enemyhealth.position.x = screen_width - 220

func _on_viewport_size_changed():
	_update_health_bar_positions()

func setup_success_label():
	success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	success_label.position.x = (get_viewport().size.x - success_label.size.x) / 2
	success_label.position.y = 20
	update_success_label(75)  # Initial value

func _on_success_rate_changed(percentage):
	update_success_label(percentage)

func update_success_label(percentage):
	success_label.text = "Success Rate: %d%%" % percentage
	if percentage >= 75:
		success_label.modulate = Color("27ae60") 
	elif percentage >= 50:
		success_label.modulate = Color("f1c40f") 
	else:
		success_label.modulate = Color("e74c3c")  
