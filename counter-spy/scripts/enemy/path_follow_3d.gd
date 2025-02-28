extends PathFollow3D

@export var period: float = 4.0

func _process(delta: float) -> void:
	progress_ratio += delta * 1.0 / period
