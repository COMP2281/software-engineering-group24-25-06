class_name ReflectiveActivity extends Control

var reflective_question_display := preload("res://scenes/prefabs/reflective_question_display.tscn")

@onready var vbox_container : VBoxContainer = $ScrollContainer/VBoxContainer

func refresh() -> void:
	var questions: Array[Question] = QuestionSelector.getReflectiveQuestions()
	
	for child in vbox_container.get_children():
		child.queue_free()
	
	for question in questions:
		var question_display : ReflectiveQuestionDisplay = reflective_question_display.instantiate()
		question_display.loadQuestion(question)
		vbox_container.add_child(question_display)
		
func prepare_enter(entered_scene) -> void:
	refresh()
	
func prepare_exit() -> void: pass

func _on_button_pressed() -> void:
	SceneCoordinator.change_scene.emit(SceneType.Name.HUB, {})
