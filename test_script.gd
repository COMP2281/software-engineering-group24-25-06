extends CSGSphere3D

var color : Color = Color(0.0, 0.0, 1.0);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (get_parent().get_node("Player/ViewZone").in_detection_range(Vector2(global_position.x, global_position.z))):
		color = Color(1.0, 0.0, 0.0);
	else:
		color = Color(0.0, 0.0, 1.0);
	
	material.albedo_color = color;
