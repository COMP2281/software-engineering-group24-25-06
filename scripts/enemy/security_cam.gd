extends Node3D

@export var viewzone_resource: ViewzoneResource

var suspicion_level: float = 0.0
var currently_seeing_player: bool = false
var player_position_guess: Vector3 = Vector3.ZERO

func _ready() -> void:
	$ViewZone.viewzone_resource = viewzone_resource
	$ViewZone.new_suspicion_level.connect(update_suspicion_level)

func update_suspicion_level(new_suspicion: float, seeing_player: bool):
	suspicion_level = new_suspicion
	currently_seeing_player = seeing_player

func _process(_delta: float) -> void:
	$ViewZone.view_direction = global_rotation.y
	player_position_guess = $ViewZone.guess_player_position()
