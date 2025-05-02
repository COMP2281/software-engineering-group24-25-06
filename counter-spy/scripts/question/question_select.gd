extends Node

# TODO: in future, likely we use the high bits for more refined search? So we can mask for
#	"I want a general question on a topic" and
#	"I want a question on this specific module of a topic"
#	Could also make these 1,2,3,4, but maybe we want questions from any topic, or some combination?
#		for example, the end boss fight might mask some specific topics you had a hard time on?
enum {
	TOPIC_AI 				= 0x00_01,
	TOPIC_CYBERSECURITY 	= 0x00_02,
	TOPIC_DATA_ANALYTICS 	= 0x00_04,
	TOPIC_CLOUD				= 0x00_08,
	TOPIC_LOW_BITS 			= 0x00_FF,
}

## NOTE: Can use these bits for selecting a specific type of question
enum {
	QUESTION_TYPE_SINGLE = 0x01_00,
	QUESTION_TYPE_MULTIPLE = 0x02_00,
	QUESTION_TYPE_BITS = 0x0F_00
}

# _seenQuestionIDMap[questionID] returns whether or not that question has been seen
# TODO: should be using packed array so data is contiguous?
var _seenQuestionIDMap : Array[bool];
var _answeredCorrectlyQuestionIDMap : Array[bool];
# TODO: should be serialised? or reset on level
var _playerSkill : float = 0.5;

# TODO: probably not the best format for storing this table data?
# Consider:
#	- vectors for each column, maybe stored in a Dictionary, using question ID as an index in these vectors
var _questionTable : Array[TableEntry];
var _questions : Array[Question];
var _maxQuestionID : int = 0;
# Track the questions we got wrong
#	for a reflective activity
var _incorrectQuestions : Array[Question];

var _rng : RandomNumberGenerator;

const DEFAULT_QUESTION_ANSWER_TIME : float = 10.0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rng = RandomNumberGenerator.new();

	loadQuestions();
	
func loadQuestions() -> void:
	var questionsFile := FileAccess.open("res://SkillsBuildQs.csv", FileAccess.READ);
	
	print("Attempted to load question: ", questionsFile)
	
	# Ignore headers
	var _headers := questionsFile.get_csv_line(",");
	
	while !questionsFile.eof_reached():
		var line := questionsFile.get_csv_line(",");
		
		var entry : TableEntry = TableEntry.new();
		
		entry.id = int(line[0]);
		entry.question = line[1];
		# TODO: filter out empty choices
		entry.choices = [line[2], line[3], line[4], line[5]];
		
		var correctChoices : PackedStringArray = line[6].split(",");
		
		entry.correctChoices = [];
		for choice in correctChoices:
			entry.correctChoices.append(int(choice));
		
		entry.module = line[7];
		entry.course = line[8];
		entry.credential = line[9];
		entry.topicID = int(line[10]);
		entry.educationLevel = line[11];
		entry.difficultyUnnormalised = int(line[12]);
		entry.relevantInfoID = int(line[13]);
		
		_questionTable.append(entry);
		_questions.append(_createQuestionFromEntry(entry));
		_maxQuestionID = max(_maxQuestionID, entry.id);
	
	questionsFile.close();
	
	_seenQuestionIDMap.resize(_maxQuestionID + 1);
	_seenQuestionIDMap.fill(false);
	
	_answeredCorrectlyQuestionIDMap.resize(_maxQuestionID + 1);
	_answeredCorrectlyQuestionIDMap.fill(false);
	
func readProgress(_player_name : String) -> void:
	# Ideally, will read some file containing some player data,
	#	- the questions they answered,
	#	- what questions they've seen
	#	- their perceived skill level - if thats something preserved between sessions
	# Depending on API, might take in the raw data in the file? Or Godot has an actual
	#	serialisation system we can use?
	pass
	
# IDs of the questions the player has seen, correctly answered, and their perceived skill level
func _loadPlayerProgress(seenQuestions : Array[int], correctlyAnsweredQuestions : Array[int], playerSkill : float) -> void:
	for seenQuestion in seenQuestions:
		_seenQuestionIDMap[seenQuestion] = true;
	
	for correctQuestion in correctlyAnsweredQuestions:
		_answeredCorrectlyQuestionIDMap[correctQuestion] = true;
	
	_playerSkill = playerSkill;
	
func _isCorrectAnswer(question : Question, answer : Array[int]) -> bool:
	# Magic button
	if -1 in answer: return true;
	
	if len(answer) != len(question.correctChoice): return false;
	
	answer.sort();
		
	for i in range(len(question.correctChoice)):
		if answer[i] != question.correctChoice[i]: return false;
	
	return true;
	
func _seenBefore(question : Question) -> bool:
	return _seenQuestionIDMap[question.id];

func _correctBefore(question : Question) -> bool:
	return _answeredCorrectlyQuestionIDMap[question.id];
	
func _createQuestionFromEntry(entry : TableEntry) -> Question:
	var question : Question = Question.new();
	
	question.answeringTime = DEFAULT_QUESTION_ANSWER_TIME;
	question.choices = entry.choices;
	question.correctChoice = entry.correctChoices;
	# TODO: Ideally we should try fit difficulties to a normal distribution?
	#	this would require two passes, and im not really bothered to implement that right now
	question.difficulty = entry.difficultyUnnormalised / 50.0;
	question.id = entry.id;
	question.text = entry.question;
	question.type = QUESTION_TYPE_SINGLE if len(entry.correctChoices) == 1 else QUESTION_TYPE_MULTIPLE;
	question.topic = entry.topicID | question.type;
	
	return question;
	
# Returns whether or not you got the question correct
#	Additionally marks that question as seen, whether it was answered correctly
#	and adjusts the player's perceived skill on some number of factors
func markQuestion(question : Question, answer : Array[int], timeSpent : float = 0.0) -> bool:
	var isCorrect : bool = _isCorrectAnswer(question, answer);
	
	# What percentage of their answering time did they use
	var answeringPercentageUsed : float = timeSpent / question.answeringTime
		
	# Assume they used half the answering time if not provided
	if timeSpent == 0.0:
		answeringPercentageUsed = 0.5
	
	# Weight of the factors in our adjustment to player skill
	# 	"The question difficulty is 10x more important than whether the player's seen it before"
	const relativeDifficultyWeight : float = 10.0; # TODO: this is difference between player skill and difficulty, more appropriate name?
	const seenWeight : float = 1.0;
	const correctWeight : float = 3.0;
	const timeWeight : float = 1.0;
	
	const totalWeight : float = relativeDifficultyWeight + seenWeight + correctWeight + timeWeight;
	const inverseTotalWeight : float = 1.0 / totalWeight;

	# TODO: Could consider a couple extra things for this algorithm
	#	- Correct answer streaks/incorrect answer streaks cause greater changes to player skill
	#	- Player skill only updates at the end of the mission, so you can't "cheese" by getting
	#	  multiple easy questions wrong to mess up the algorithm
	
	# Temperature might not be the right word,
	#	"How aggressive is the algorithm in adjusting player skill?"
	const temperature : float = 0.1; # Value... fresh from my ass

	# Ideally we want the user to answer correctly ~80% of the time?
	#	so adjust how we correct player skill such that getting
	#	correct answers 80% of the time leads to net 0 change in
	#	skill level (approximately)
	const targetLossRate : float = 0.20;
	const bias: float = -1.0 + targetLossRate;
	
	# Note logic for (seen/previously correct) and correct:
	#	 Seen &&  Correct -> small change
	#	!Seen && !Correct -> small change
	#	!Seen &&  Correct -> big change
	#	 Seen && !Correct -> big change
	# Hence the XOR operation (!=)
	
	# Logic for answering percentage
	#	notably attempting to disincentivise a quick guess
	#	low answer && correct -> big change
	# 	high answer && correct -> small change
	# 	high answer && !correct -> small change
	#	low answer && !correct -> big change
	
	_playerSkill += (int(isCorrect) + bias) * temperature * inverseTotalWeight * (
		# TODO: this relative difficulty weight is pretty dodgy
		# TODO: at the very least, this should be linearly scaled to the range [0, 1]
		#	but right now, it ranges from [e^-2, 1]
		# Essentially
		#	- if the player skill is far below question difficulty, more dramatic change (capped at 1)
		#	- if player skill is far above question difficulty, less dramatic change (capped at e^-2)
		#	- if player skill exactly matches question difficulty, less dramatic change (around e^-1)
		(exp(-(_playerSkill - question.difficulty) - 1.0) * relativeDifficultyWeight) +
		(int(_seenBefore(question) != isCorrect) * seenWeight) +
		(int(_correctBefore(question) != isCorrect) * correctWeight) +
		((1.0 - answeringPercentageUsed) * timeWeight)
	);
	
	_playerSkill = clamp(_playerSkill, 0.0, 1.0);
	
	# Mark question as correctly answered or not
	#	It's somewhat intentional that if you got a question correct, and then get the same question
	#	wrong, that question is now marked as never answered correctly
	#	Justification is that maybe you forget the question's answer, thus unfair to continue to
	#	mark as answered correctly
	_answeredCorrectlyQuestionIDMap[question.id] = isCorrect;
	_seenQuestionIDMap[question.id] = true;
	
	if not isCorrect:
		_incorrectQuestions.append(question)
	
	return isCorrect;
	
# TODO: probably take question itself instead of question mask? to be more similar to _seenBefore
func _doesTopicMatch(questionMask : int, requestedMask : int) -> bool:
	# For now, we just check the low bits of the question mask is a subset of the requested mask
	#	Could simplify, but wanna make clear we're comparing only low bits of both
	#	questionMask & requestedMask & TOPIC_LOW_BITS
	var lowBitsMatch: bool = bool((questionMask & TOPIC_LOW_BITS) & (requestedMask & TOPIC_LOW_BITS));
	var questionTypeMatch: bool = (requestedMask & QUESTION_TYPE_BITS == 0) || ((questionMask & QUESTION_TYPE_BITS) & (requestedMask & QUESTION_TYPE_BITS));
	
	return lowBitsMatch and questionTypeMatch;
	
# Difficulty of a question relative to a player's skill
func _relativeDifficulty(question : Question) -> float:
	const playerSkillEffect: float = 0.2; # Varify question difficulty by at most 0.2 (+-)
	# TODO: check math
	var playerSkillModifier: float = (1.0 - _playerSkill - 0.5) * playerSkillEffect * 2 + 1.0; # Value ranging [0.8, 1.2]
	
	return clamp(question.difficulty * playerSkillModifier, 0.0, 1.0);
	
func _calculateAnsweringTime(_question : Question) -> float:
	# Based off the player's perceived difficulty of question
	# TODO: could be time per word, might be more accurate
	const timePerCharacter: float = 0.1;
	var perceivedDifficulty: float = _relativeDifficulty(_question);
	
	var baselineTime: float = timePerCharacter * len(_question.text);
	baselineTime *= (perceivedDifficulty + 0.5);
	
	return baselineTime;
	
# Return a list of questions to reflect on
func getReflectiveQuestions() -> Array[Question]:
	return _incorrectQuestions;
	
# Given a certain topic, and requesting a certain difficulty of question [0..1],
#	try to find the most appropriate question
func selectQuestion(topicMask : int, requestedDifficulty : float) -> Question:
	const topicMatchingWeight : float = 1000.0;
	const seenWeight : float = 5.0;
	const difficultyWeight : float = 1.0;

	const totalWeight : float = topicMatchingWeight + seenWeight + difficultyWeight;
	const inverseTotalWeight : float = 1.0 / totalWeight;
	
	const randomVariance : float = 0.2;
	
	var bestQuestionScore : float = 0.0;
	var bestQuestion : Question = null;
	
	for question in _questions:
		var questionScore : float = inverseTotalWeight * (
			int(_doesTopicMatch(question.topic, topicMask)) * topicMatchingWeight +
			(1.0 - int(_seenBefore(question))) * seenWeight + # Note, negatively weighted
			(1.0 - abs(_relativeDifficulty(question) - requestedDifficulty)) * difficultyWeight
			+ _rng.randf_range(-randomVariance, randomVariance)
		);
		
		if questionScore > bestQuestionScore:
			bestQuestionScore = questionScore;
			bestQuestion = question;

	bestQuestion.answeringTime = _calculateAnsweringTime(bestQuestion);
	
	return bestQuestion;
