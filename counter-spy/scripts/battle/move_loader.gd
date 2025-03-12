extends Node

var loadedMoves : Array[Move]
var movesByType : Dictionary
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	var movesDict = JSON.parse_string(FileAccess.get_file_as_string("res://settings/moves/moves.json"))
	var movesList = movesDict["moves"]
	
	for move in movesList:
		var moveObject : Move = Move.new()
		moveObject.name = move["moveName"]
		moveObject.type = move["type"]
		moveObject.difficulty = move["difficulty"]
		moveObject.damage = move["damage"]
		
		loadedMoves.append(moveObject)
		
		if moveObject.type not in movesByType:
			movesByType[moveObject.type] = []
			
		movesByType[moveObject.type].append(moveObject)
		
func shuffle(list : Array) -> Array:
	var out: Array = list.duplicate(false)
	
	# Fisher-Yates shuffle
	for i in range(len(out) - 1, 0, -1):
		var j : int = rng.randi_range(0, i)
		
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
		
	return out
		
## NOTE: Might not give all moves if excessive number requested (>20)
# TODO: should select moves based on weights of ultimates/etc. where possible
func selectMove(numMoves : int) -> Array[Move]:
	var selectedMoves: Array[Move] = []
	var typesToSelect: Array[String] = ["generic", "fire", "water", "plant"]
	var typesSelected: int = 0;
	
	typesToSelect = shuffle(typesToSelect)
	
	for type in typesToSelect:
		var movesOfType = shuffle(movesByType[type])
		
		var leftToSelect: int = numMoves - len(selectedMoves)
		var selectFromType: int
		if typesSelected > 0:
			selectFromType = leftToSelect / (len(typesToSelect) / typesSelected)
		else:
			selectFromType = leftToSelect
		typesSelected += 1
		
		for i in range(min(selectFromType, len(movesOfType))):
			selectedMoves.append(movesOfType[i])
		
	return selectedMoves
