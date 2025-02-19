# questions.gd (attach to QuestionManager)
extends Node

var questions = {}
var current_question = null

func _ready():
	load_questions()

func load_questions():
	var file = FileAccess.open("res://questions.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.parse_string(json_string)
		if json and "Question" in json:
			for q in json.Question:
				var credential = q.credential
				if not (credential in questions):
					questions[credential] = []
				questions[credential].append({
					"question": q.question,
					"options": [
						q.choice1,
						q.choice2,
						q.choice3,
						q.choice4
					],
					"correctAnswer": q.correctChoices,
				})
		file.close()
		print("Questions loaded successfully")
	else:
		print("Failed to load questions file")

func get_question(credential):
	if credential in questions:
		var available_questions = questions[credential]
		if available_questions.size() > 0:
			var index = randi() % available_questions.size()
			current_question = available_questions[index]
			return current_question
	return null

func check_answer(answer):
	if current_question:
		return int(answer) == current_question.correctAnswer
