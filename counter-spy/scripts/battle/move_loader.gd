extends Node

var loaded_moves : Array[Move]
var moves_by_type : Dictionary
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	var moves_dict = JSON.parse_string(FileAccess.get_file_as_string("res://settings/moves/moves.json"))
	var moves_list = moves_dict["moves"]
	
	for move in moves_list:
		var move_object : Move = Move.new()
		move_object.name = move["moveName"]
		move_object.type = move["type"]
		move_object.difficulty = move["difficulty"]
		move_object.damage = move["damage"]
		
		loaded_moves.append(move_object)
		
		if move_object.type not in moves_by_type:
			moves_by_type[move_object.type] = []
			
		moves_by_type[move_object.type].append(move_object)
		
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
# TODO: select moves on damage instead of randomly on type
# TODO: always select set amount of attacks?
func selectMove(numMoves : int) -> Array[Move]:
	var selected_moves: Array[Move] = []
	var types_to_select: Array[String] = ["generic", "fire", "water", "plant"]
	var typed_selected: int = 0;
	
	for type in types_to_select:
		var moves_of_type: Array[Move] = shuffle(moves_by_type[type]) as Array[Move]
		
		var left_to_select: int = numMoves - len(selected_moves)
		var select_from_type: int = left_to_select / (len(types_to_select) / typed_selected)
		typed_selected += 1
		
		for i in range(min(select_from_type, len(moves_of_type))):
			selected_moves.append(moves_of_type[i])
		
	return selected_moves
