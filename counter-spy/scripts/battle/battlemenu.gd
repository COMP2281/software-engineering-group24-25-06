extends Control

signal option_selected(option)

var options = ["ATTACK", "GUARD", "ITEM", "ATTACK2"]
var menu_visible = false
var selected_index = 0
var buttons = []  # Store button references

func _ready():
	setup_menu()
	hide_menu()

func _input(event):
	if !menu_visible:
		return
		
	if event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % 4
		update_selection()
	elif event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1) % 4
		if selected_index < 0:
			selected_index = 3
		update_selection()
	elif event.is_action_pressed("ui_accept"):
		_on_option_pressed(selected_index)

func update_selection():
	for i in range(buttons.size()):
		var button = buttons[i]
		var style = button.get_theme_stylebox("normal").duplicate()
		if i == selected_index:
			style.bg_color = Color(1, 0, 0, 0.3)
			style.border_color = Color(1, 0, 0)
		else:
			style.bg_color = Color(0, 0, 0, 0.9)
			style.border_color = Color(0.5, 0, 0)
		button.add_theme_stylebox_override("normal", style)

func setup_menu():
	var wheel = $Wheelcontainer
	buttons.clear()  # Clear any existing buttons
	
	# Style the container like P5
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.border_color = Color(1, 0, 0)
	style.corner_radius_top_left = 10
	
	# TODO: ideally keep the wheel-based positioning system
	#	but also allow it to scale nicely
	for i in range(options.size()):
		var button = Button.new()
		var angle = (i * PI/2) - PI/4
		
		# P5 style positioning
		var radius = 150
		var pos = Vector2(
			cos(angle) * radius + 200,
			sin(angle) * radius + 200
		)
		
		# Style the button P5 style
		button.text = options[i]
		button.custom_minimum_size = Vector2(120, 40)
		button.position = pos - button.custom_minimum_size/2
		
		# P5 styling
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0, 0, 0, 0.9)
		btn_style.border_color = Color(1, 0, 0)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_bottom_right = 10
		btn_style.skew = Vector2(0.2, 0)
		
		button.add_theme_stylebox_override("normal", btn_style)
		button.connect("pressed", _on_option_pressed.bind(i))
		
		# Add P5 style controls indicator
		var control_label = Label.new()
		control_label.text = "○ " if i == 0 else "□ " if i == 1 else "△ " if i == 2 else "× "
		control_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button.add_child(control_label)
		
		wheel.add_child(button)
		buttons.append(button)  # Store button reference

func show_menu():
	menu_visible = true
	show()
	selected_index = 0
	update_selection()

func hide_menu():
	menu_visible = false
	hide()

func _on_option_pressed(index):
	var options = ["ATTACK", "GUARD", "ITEM", "WEAKNESS"]
	emit_signal("option_selected", options[index])
