class_name TableEntry

var id : int;
var question : String;
var choices : Array[String];
var correctChoices : Array[int];
var module : String;
var course : String;
var credential : String;
var topicID : int;
var educationLevel : String;
var difficultyUnnormalised : int;
var relevantInfoID : int;

# TODO: two calculated properties, not the best place for them?
var trueDifficulty : float; # Normalised difficulty
var normalisedLength : float; # Normalised question length
