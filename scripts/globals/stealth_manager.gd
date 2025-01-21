extends Node

var SUSPICION_LEVEL : float = 0.0;
signal changeSusLevel(newLevel:float)

func _ready() -> void:
	changeSusLevel.connect(updateSusLevel)

func _process(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy") as Array[Enemy]
	if not enemies: return
	var max_sus_level = enemies[0].SUSPICION_LEVEL
	for enemy in enemies:
		if enemy.SUSPICION_LEVEL > max_sus_level:
			max_sus_level = enemy.SUSPICION_LEVEL
	if SUSPICION_LEVEL != max_sus_level: changeSusLevel.emit(max_sus_level)

func updateSusLevel(newLevel:float):
	SUSPICION_LEVEL = newLevel
