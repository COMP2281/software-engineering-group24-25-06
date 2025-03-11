class_name MissionNode extends Node3D

var loaded_level = null;
var loaded_level_name: String = "";

func _ready() -> void:
	pass

func entered_from_encounter(data: Dictionary) -> void:
	if data == {}: return
	
	var enemy: Enemy = data["enemy_defeated"] as Enemy
	
	if enemy == null:
		push_warning("Exited from battle scene without a defeated enemy")
		return
	
	# lol
	enemy.die()
	
	StealthManager.set_all_suspicion_level.emit(0.0)
	
func load_level(level_name) -> void:
	# If attempting to load the same level, return
	if loaded_level != null and loaded_level_name == level_name: return
		
	if loaded_level != null:
		remove_child(loaded_level)
		loaded_level.queue_free()
	
	var packed_scene := load(level_name)
	loaded_level_name = level_name
	loaded_level = packed_scene.instantiate()
	add_child(loaded_level)
	
func reset_level() -> void:
	remove_child(loaded_level)
	loaded_level.queue_free()
	loaded_level = null
	
	var packed_scene := load(loaded_level_name)
	loaded_level = packed_scene.instantiate()
	add_child(loaded_level)
	
func prepare_enter() -> void:
	if loaded_level != null:
		loaded_level.prepare_enter()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func prepare_exit() -> void:
	if loaded_level != null:
		loaded_level.prepare_exit()
