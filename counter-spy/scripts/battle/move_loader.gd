extends Node

# Array to store all loaded attack moves
var loadedMoves : Array[Move]

# Dictionary to organize moves by their type (fire, water, plant, etc.)
var movesByType : Dictionary

# Random number generator for shuffling
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

# Initialize the move loader system
func _ready() -> void:
	# Load the moves.json file that contains all attack definitions
	var movesDict = JSON.parse_string(FileAccess.get_file_as_string("res://settings/moves/moves.json"))
	var movesList = movesDict["moves"]
	
	# Process each move from the JSON and convert it to a Move object
	for move in movesList:
		var moveObject : Move = Move.new()
		moveObject.name = move["moveName"]
		moveObject.type = move["type"]
		moveObject.difficulty = move["difficulty"]
		moveObject.damage = move["damage"]
		
		# Add to the main moves list
		loadedMoves.append(moveObject)
		
		# Organize moves by type for easier selection later
		if moveObject.type not in movesByType:
			movesByType[moveObject.type] = []
			
		movesByType[moveObject.type].append(moveObject)
		
# Shuffle an array using Fisher-Yates algorithm
# Returns a new shuffled array without modifying the original
func shuffle(list : Array) -> Array:
	var out: Array = list.duplicate(false)
	
	# Fisher-Yates shuffle - efficiently randomizes array in-place
	for i in range(len(out) - 1, 0, -1):
		var j : int = rng.randi_range(0, i)
		
		# Swap elements
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
		
	return out
		
# Select a number of moves with type variety
# NOTE: Might not give all moves if excessive number requested (>20)
# TODO: should select moves based on weights of ultimates/etc. where possible
# TODO: select moves on damage instead of randomly on type
# TODO: always select set amount of attacks?
func selectMove(numMoves : int) -> Array[Move]:
	var selectedMoves: Array[Move] = []
	
	# Available move types
	var typesToSelect: Array[String] = ["generic", "fire", "water", "plant"]
	var typesSelected: int = 0;
	
	# Randomize the order of types to select
	typesToSelect = shuffle(typesToSelect)
	
	# Try to select a balanced variety of move types
	for type in typesToSelect:
		# Get shuffled moves of this type
		var movesOfType = shuffle(movesByType[type])
		
		# Calculate how many moves to select from this type
		var leftToSelect: int = numMoves - len(selectedMoves)
		var selectFromType: int
		if typesSelected > 0:
			# Distribute remaining selections across remaining types
			selectFromType = leftToSelect / (len(typesToSelect) / typesSelected)
		else:
			# For first type, take proportional amount
			selectFromType = leftToSelect
		typesSelected += 1
		
		# Add moves of this type to selection
		for i in range(min(selectFromType, len(movesOfType))):
			selectedMoves.append(movesOfType[i])
		
	return selectedMoves
