extends Control

signal option_selected(option)

var options = ["ATTACK", "ATTACK3", "ITEMS", "ATTACK2"]
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
	
	for child in wheel.get_children():
		child.queue_free()
		
	var player = get_tree().get_root().get_node("Battle/player")  # Adjust path as needed
	var player_pos = Vector2(400, 400)  
	
	if player:
		var viewport = get_viewport()
		var camera = viewport.get_camera_3d()
		if camera:
			player_pos = camera.unproject_position(player.global_position)
		
	var initial_angle: float = PI / 4.0
	var angle_change: float = (2.0* PI) / float(options.size())
	var radius = 150
	
	for i in range(options.size()):
		var button = Button.new()
		var angle = (i * angle_change) + initial_angle
		
		var pos = Vector2(
			cos(angle) * radius + 200,
			sin(angle) * radius + 200
		)
		
		button.text = options[i]
		button.custom_minimum_size = Vector2(120, 40)
		button.position = pos - button.custom_minimum_size/2
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0, 0, 0, 0.9)
		btn_style.border_color = Color(1, 0, 0)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_bottom_right = 10
		button.add_theme_stylebox_override("normal", btn_style)
		
		button.connect("pressed", _on_option_pressed.bind(i))
		
		var control_label = Label.new()
		control_label.text = "○ " if i == 0 else "□ " if i == 1 else "△ " if i == 2 else "× "
		control_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button.add_child(control_label)
		wheel.add_child(button)
		buttons.append(button)
	
	if not is_connected("draw", _draw):
		connect("draw", _draw)
		

func _draw():
	if not visible:
		return
		
	var player = get_tree().get_root().get_node("Battle/player")
	if not player:
		return
		
	var player_pos = Vector2(400, 400)
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	if camera:
		player_pos = camera.unproject_position(player.global_position)
   
	for button in buttons:
		var button_center = button.position + button.custom_minimum_size/2
		draw_line(player_pos, button_center, Color(1, 0, 0), 2)

func show_menu():
	menu_visible = true
	show()
	selected_index = 0
	update_selection()

func hide_menu():
	menu_visible = false
	hide()

func update_options(new_options):
	options = new_options
	setup_menu()

func _on_option_pressed(index):
	if index < options.size():
		emit_signal("option_selected", options[index])
	else:
		print("Invalid index")
