extends Node

# File path to store saved data
const SAVE_PATH = "res://saves/save_data.json"

# Variables to track level status
var lvl1: bool = false
var lvl2: bool = false
var lvl3: bool = false
var lvl4: bool = false
var lvl5: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_game()  # Load saved data when the game starts

# Function to save the game state
func save_game() -> void:
	var save_data = {
		"lvl1": lvl1,
		"lvl2": lvl2,
		"lvl3": lvl3,
		"lvl4": lvl4,
		"lvl5": lvl5
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))  # Format JSON with indentation
		file.close()

# Function to load the game state
func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var data = JSON.parse_string(json_text)
			if data:
				lvl1 = data.get("lvl1", false)
				lvl2 = data.get("lvl2", false)
				lvl3 = data.get("lvl3", false)
				lvl4 = data.get("lvl4", false)
				lvl5 = data.get("lvl5", false)
