extends Node3D

var in_area = false
var opened = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label3D.hide()

func _process(delta: float) -> void:
	$AnimationTree.set("parameters/blend_position", lerpf($AnimationTree.get("parameters/blend_position"),opened,delta))

func _input(event: InputEvent) -> void:
	if in_area and event.is_action_pressed("interact"):
		opened = !opened

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		in_area = true
		$Label3D.show()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		in_area = false
		$Label3D.hide()
