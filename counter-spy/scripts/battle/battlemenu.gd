extends Control

# Signal emitted when player selects an attack option
signal option_selected(option)

# Default menu options
var options = ["ATTACK", "ATTACK3", "ITEMS", "ATTACK2"]

# Menu state tracking
var menu_visible = false
var selected_index = 0
var buttons = []  # Store button references

# Initialize menu when the node is ready
func _ready():
	setup_menu()
	hide_menu()

# Handle player input for keyboard navigation
func _input(event):
	# Skip processing if menu isn't visible
	if !menu_visible:
		return
	
	# Navigate menu with arrow keys	
	if event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % 4
	elif event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1) % 4
	elif event.is_action_pressed("ui_accept"):
		# Select current option with Enter/Space
		on_option_pressed(selected_index)

# Create the battle menu UI in a radial layout
func setup_menu():
	var wheel = $Wheelcontainer
	buttons.clear()  # Clear any existing buttons
	
	# Remove any existing UI elements
	for child in wheel.get_children():
		child.queue_free()
	
	# Center point for the radial menu
	# Note: This position is hardcoded based on default screen layout
	# TODO (minor): breaks with very vertical screens because of how window resizes
	var player_center = Vector2(350, 375)
	
	# Radial menu configuration
	var radius = 200  # Distance from center
	var initial_angle = 3.5 * PI / 4  # Starting angle (upper left)
	var angle_span = 5 * PI / 12  # How much of the circle to cover
	
	# Create buttons for each option
	for i in range(options.size()):
		var container = Control.new()
		wheel.add_child(container)
		
		var button = Button.new()
		
		# Calculate position on the radial layout
		var angle = (i * angle_span / (options.size() - 1)) + initial_angle
		var pos = Vector2(
			cos(angle) * radius + player_center.x,
			sin(angle) * radius + player_center.y
		)
		
		# Create stylish button with cyberpunk/tech feel
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0, 0, 0, 0.9)
		btn_style.border_color = Color(1, 0, 0)
		btn_style.corner_radius_top_left = 15
		btn_style.corner_radius_bottom_right = 15
		btn_style.skew = Vector2(0.2, 0)  # Gives angular appearance
		
		# Set button properties
		button.text = options[i]
		button.custom_minimum_size = Vector2(150, 40)
		button.position = pos - button.custom_minimum_size/2
		button.add_theme_stylebox_override("normal", btn_style)
		
		# Create hover state style
		var hover_style = btn_style.duplicate()
		hover_style.bg_color = Color(0.4, 0, 0, 0.9)
		hover_style.border_color = Color(1, 0.3, 0.3)
		
		# Create pressed state style
		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = Color(0.6, 0, 0, 0.9)
		
		# Add label for button text
		var label = Label.new()
		label.text = options[i]
		label.position = button.position + Vector2(10, 5)
		
		# Connect hover and click signals
		button.mouse_entered.connect(func(): on_button_hover(button, true))
		button.mouse_exited.connect(func(): on_button_hover(button, false))
		button.connect("pressed", on_option_pressed.bind(i))
		
		# Add control indicator label
		var control_label = Label.new()
		control_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button.add_child(control_label)
		
		# Add button to scene and store reference
		wheel.add_child(button)
		buttons.append(button)
		
		# Create fade-in animation
		button.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(i * 0.1)

# Handle button hover animations
func on_button_hover(button, is_hovering):
	var tween = create_tween()
	if is_hovering:
		# Grow button slightly when hovered
		tween.tween_property(button, "custom_minimum_size", Vector2(160, 45), 0.1)
		tween.parallel().tween_property(button, "position", button.position - Vector2(5, 2.5), 0.1)
	else:
		# Return to normal size when not hovered
		tween.tween_property(button, "custom_minimum_size", Vector2(150, 40), 0.1)
		tween.parallel().tween_property(button, "position", button.position + Vector2(5, 2.5), 0.1)

# Show the menu and reset selection
func show_menu():
	menu_visible = true
	show()
	selected_index = 0

# Hide the menu
func hide_menu():
	menu_visible = false
	hide()

# Update the menu with new options
func update_options(new_options):
	options = new_options
	setup_menu()

# Handle option selection
func on_option_pressed(index):
	if index < options.size():
		# Emit signal with the selected option text
		emit_signal("option_selected", options[index])
	else:
		print("Invalid index")
