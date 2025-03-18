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
	
	# Static position, because of how window resizes should be fine?
	# TODO (minor): breaks with very vertical screens because of how window resizes
	var player_center = Vector2(350, 375)
	
	var radius = 200
	var initial_angle = 3.5 * PI / 4
	var angle_span =  5 * PI / 12
	
	for i in range(options.size()):
		var container = Control.new()
		wheel.add_child(container)
		
		var button = Button.new()
		var angle = (i * angle_span / (options.size() - 1)) + initial_angle
		
		var pos = Vector2(
			cos(angle) * radius + player_center.x,
			sin(angle) * radius + player_center.y
		)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0, 0, 0, 0.9)
		btn_style.border_color = Color(1, 0, 0)
		btn_style.corner_radius_top_left = 15
		btn_style.corner_radius_bottom_right = 15
		btn_style.skew = Vector2(0.2, 0)
		
		button.text = options[i]
		button.custom_minimum_size = Vector2(150, 40)
		button.position = pos - button.custom_minimum_size/2
		button.add_theme_stylebox_override("normal", btn_style)
		
		var hover_style = btn_style.duplicate()
		hover_style.bg_color = Color(0.4, 0, 0, 0.9)
		hover_style.border_color = Color(1, 0.3, 0.3)
		
		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = Color(0.6, 0, 0, 0.9)
		
		var label = Label.new()
		label.text = options[i]
		label.position = button.position + Vector2(10, 5)
		
		button.mouse_entered.connect(func(): _on_button_hover(button, true))
		button.mouse_exited.connect(func(): _on_button_hover(button, false))
		
		button.connect("pressed", _on_option_pressed.bind(i))
		
		var control_label = Label.new()
		control_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button.add_child(control_label)
		wheel.add_child(button)
		buttons.append(button)
		
		button.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(i * 0.1)

func _on_button_hover(button, is_hovering):
	var tween = create_tween()
	if is_hovering:
		tween.tween_property(button, "custom_minimum_size", Vector2(160, 45), 0.1)
		tween.parallel().tween_property(button, "position", button.position - Vector2(5, 2.5), 0.1)
	else:
		tween.tween_property(button, "custom_minimum_size", Vector2(150, 40), 0.1)
		tween.parallel().tween_property(button, "position", button.position + Vector2(5, 2.5), 0.1)

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
