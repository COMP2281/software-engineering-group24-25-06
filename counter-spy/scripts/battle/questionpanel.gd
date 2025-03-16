extends VBoxContainer

signal answer_selected(answer)

func _ready():
	style_panel()
	
	visible = true
	print("Panel is ready and visible")
	
func style_panel():
	
	show()
	
	custom_minimum_size = Vector2(600, 400)
	
	$Container/Questionlabel.custom_minimum_size = Vector2(580, 100)
	
	$Optionscontainer.custom_minimum_size = Vector2(580, 250)
	
func show_question(question: Question):
	show()
	$Container/Questionlabel.text = question.text
	print("Label text set to: ", $Container/Questionlabel.text)
	
	for child in $Optionscontainer.get_children():
		child.queue_free()
		
	for i in range(question.choices.size()):
		var button = Button.new()
		button.text = str(question.choices[i])
		
		button.custom_minimum_size = Vector2(560, 50)
		
		button.connect("pressed", _on_answer_selected.bind(i + 1))
		$Optionscontainer.add_child(button)
	
	# TODO: terrible magic button	
	var magic_button = Button.new()
	magic_button.text = "Magic button"
	
	magic_button.custom_minimum_size = Vector2(560, 60)
	
	magic_button.connect("pressed", _on_answer_selected.bind(-1))
	$Optionscontainer.add_child(magic_button)

func _on_answer_selected(answer):
	emit_signal("answer_selected", answer)
	hide()
