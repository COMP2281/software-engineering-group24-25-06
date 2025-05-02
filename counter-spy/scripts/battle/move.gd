# Move.gd
# This class represents an attack move in the battle system
# Each move has a specific type (element), damage value, and difficulty
class_name Move

# The name of the attack move (displayed in battle menu)
var name: String

# How much damage this move deals when successfully executed
var damage: int

# The elemental type of the move (fire, water, plant, generic, etc.)
# Different types may be effective against specific enemies
var type: String

# The difficulty level of this move
# Likely affects either question difficulty or success chance
var difficulty: int
