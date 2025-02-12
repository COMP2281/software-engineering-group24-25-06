class_name Enemy extends MeshInstance3D

@export var health:int = 100
@onready var battle_scene:PackedScene = preload("res://Battle.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite3D.hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

var new_encounter:Encounter
func _on_area_3d_body_entered(body: Node3D) -> void:
	$"../Control/Panel/AnimationPlayer".play("lock_in")
	$"../ProtoController3P".can_move = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await $"../Control/Panel/AnimationPlayer".animation_finished
	new_encounter = battle_scene.instantiate()
	get_tree().root.add_child(new_encounter)
	new_encounter.canvas.hide()
	new_encounter.camera.make_current()
	new_encounter.encounter_done.connect(byebye)
	$"..".hide()
	await get_tree().create_timer(1).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$"../Control/Panel/AnimationPlayer".play("lock_out")
	await $"../Control/Panel/AnimationPlayer".animation_finished
	new_encounter.canvas.show()
	pass # Replace with function body.

@onready var body_mark:Sprite3D = preload("res://body_mark.tscn").instantiate()

func byebye():
	new_encounter.queue_free()
	$"..".show()
	get_tree().current_scene.add_child(body_mark)
	body_mark.global_position = global_position - Vector3(0,1,0) + Vector3(0,0.001,0)
	$"../ProtoController3P".can_move = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func _on_area_3d_2_body_entered(body: Node3D) -> void:
	print("collided")
	$Sprite3D.show()
	pass # Replace with function body.


func _on_area_3d_2_body_exited(body: Node3D) -> void:
	$Sprite3D.hide()
	pass # Replace with function body.
