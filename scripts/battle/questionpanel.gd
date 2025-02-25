extends Panel

signal answer_selected(answer)

func _ready():
	style_panel()
	
	visible = true
	print("Panel is ready and visible")
	
func style_panel():
	
	show()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.border_color = Color(1, 0, 0)
	style.corner_radius_top_left = 15
	style.corner_radius_bottom_right = 15
	add_theme_stylebox_override("panel", style)
	
	custom_minimum_size = Vector2(600, 400)
	position = Vector2(
		(get_viewport().size.x - custom_minimum_size.x) / 2,
		(get_viewport().size.y - custom_minimum_size.y) / 2
	)
	
	$Questionlabel.add_theme_color_override("font_color", Color.WHITE)
	$Questionlabel.custom_minimum_size = Vector2(580, 100)
	$Questionlabel.position = Vector2(10, 20)
	
	$Optionscontainer.custom_minimum_size = Vector2(580, 250)
	$Optionscontainer.position = Vector2(10, 20)
	$Optionscontainer.add_theme_constant_override("seperation", 20)
	
func show_question(question: Question):
	
	show()
	print("Showing question in question_panel:", question.text)
	$Questionlabel.text = question.text
	print("Label text set to: ", $Questionlabel.text)
	
	for child in $Optionscontainer.get_children():
		child.queue_free()
		
	for i in range(question.choices.size()):
		var button = Button.new()
		button.text = str(question.choices[i])
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0, 0, 0, 0.8)
		btn_style.border_color = Color(1, 0, 0)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_bottom_right = 10
		
		button.custom_minimum_size = Vector2(560, 50)
		button.add_theme_stylebox_override("normal", btn_style)
		button.add_theme_color_override("font_style", Color.WHITE)
		button.add_theme_font_size_override("font_size", 16)
		
		button.connect("pressed", _on_answer_selected.bind(i + 1))
		$Optionscontainer.add_child(button)
	
	# TODO: terrible magic button	
	var magic_button = Button.new()
	magic_button.text = "Magic button"
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0.8)
	btn_style.border_color = Color(1, 0, 0)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_bottom_right = 10
	
	magic_button.custom_minimum_size = Vector2(560, 60)
	magic_button.add_theme_stylebox_override("normal", btn_style)
	magic_button.add_theme_color_override("font_style", Color.WHITE)
	magic_button.add_theme_font_size_override("font_size", 16)
	
	magic_button.connect("pressed", _on_answer_selected.bind(-1))
	$Optionscontainer.add_child(magic_button)

func _on_answer_selected(answer):
	emit_signal("answer_selected", answer)
	hide()
