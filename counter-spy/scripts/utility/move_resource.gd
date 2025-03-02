class_name MoveResource extends Resource

enum Element {
	GENERIC,
	FIRE,
	WATER,
	PLANT
}

## Attack name
@export var name: String = ""
## Damage value
@export var damage: int = 0
## Difficulty store from 1-5
@export_range(1, 5) var difficulty: int = 1
## Move damage type
@export var type: Element = Element.GENERIC
