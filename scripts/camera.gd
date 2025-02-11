extends Camera3D

func _ready():
	transform.origin = Vector3(-6, 3, 6)
	look_at(Vector3(0, 1, 0))
	projection = Camera3D.PROJECTION_PERSPECTIVE
	fov = 60
