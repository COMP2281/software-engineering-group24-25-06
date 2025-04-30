class_name ReflectiveQuestionDisplay extends Control

func loadQuestion(question: Question):
	$VBoxContainer/PanelContainer/QuestionText.text = question.text
	# TODO: only handles single answers
	$VBoxContainer/PanelContainer2/Answer.text = question.choices[question.correctChoice[0] - 1]
