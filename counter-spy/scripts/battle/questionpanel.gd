extends VBoxContainer

# Signal to notify when player selects an answer
signal answer_selected(answer)

# Initialize the panel when ready
func _ready():
	# Apply visual styling
	style_panel()
	
	# Make panel visible by default
	visible = true
	print("Panel is ready and visible")
	
# Configure the visual appearance of the question panel
func style_panel():
	# Ensure panel is visible
	show()
	
	# Set overall panel size
	custom_minimum_size = Vector2(600, 400)
	
	# Set question text area size
	$Container/Questionlabel.custom_minimum_size = Vector2(580, 100)
	
	# Set answer options container size
	$Optionscontainer.custom_minimum_size = Vector2(580, 250)
	
# Display a question with its answer choices
func show_question(question: Question):
	# Make panel visible
	show()
	
	# Set the question text
	$Container/Questionlabel.text = question.text
	print("Label text set to: ", $Container/Questionlabel.text)
	
	# Clear any existing answer buttons
	for child in $Optionscontainer.get_children():
		child.queue_free()
	
	# Create a button for each answer choice
	for i in range(question.choices.size()):
		var button = Button.new()
		button.text = str(question.choices[i])
		
		# Set consistent button size
		button.custom_minimum_size = Vector2(560, 50)
		
		# Connect button press to answer selection
		# Note: answer indexes start at 1 (i+1)
		button.connect("pressed", on_answer_selected.bind(i + 1))
		$Optionscontainer.add_child(button)
	
	# TODO: terrible magic button
	# This appears to be a debugging feature or cheat button
	var magic_button = Button.new()
	magic_button.text = "Magic button"
	
	magic_button.custom_minimum_size = Vector2(560, 60)
	
	# Magic button sends special answer code -1
	magic_button.connect("pressed", on_answer_selected.bind(-1))
	$Optionscontainer.add_child(magic_button)

# Handle player's answer selection
func on_answer_selected(answer):
	# Forward the selected answer through the signal
	emit_signal("answer_selected", answer)
	
	# Hide the panel after selection
	hide()
