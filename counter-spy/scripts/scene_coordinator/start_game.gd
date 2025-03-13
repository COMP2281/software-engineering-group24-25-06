extends Button

var main_scene: PackedScene = preload("res://scenes/missions/main.tscn")

func _on_pressed() -> void:
	get_tree().change_scene_to_packed(main_scene)
