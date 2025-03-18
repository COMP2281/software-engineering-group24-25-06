extends Area3D

@onready var proto_controller: ProtoController = $"../Player/ProtoController3P"

var in_area: bool = false

func _process(_delta: float) -> void:
	if in_area and Input.is_action_pressed("interact"):
		print("Changing to minigame!")
		SceneCoordinator.change_scene.emit(SceneType.Name.MINIGAME, { "entered_from": SceneType.Name.HUB })

func _on_body_entered(body: Node3D) -> void:
	if body.name == "ProtoController3P":
		$Tooltip.show()
		in_area = true
	else:
		print("Not player entered: ", body.name)

func _on_body_exited(body: Node3D) -> void:
	if body.name == "ProtoController3P":
		$Tooltip.hide()
		in_area = false
