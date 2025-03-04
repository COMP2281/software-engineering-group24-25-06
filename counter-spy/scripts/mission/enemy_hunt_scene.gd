class_name MissionNode extends Node3D

func entered_from_encounter(data: Dictionary) -> void:
	if data == {}: return
	
	var enemy: Enemy = data["enemy_defeated"] as Enemy
	
	if enemy == null:
		push_warning("Exited from battle scene without a defeated enemy")
		return
	
	# lol
	enemy.die()

func prepare_enter() -> void:
	$Player.show_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func prepare_exit() -> void:
	$Player.hide_ui()
