extends Camera3D

func _ready():
	# This function is executed when the camera node is added to the scene tree
	
	# TODO: TEMPORARY - This whole setup is temporarily disabled
	# TODO: also just make it set to these positions instead of doing it in a ready script
	return  # Early return prevents the code below from executing
	
	# Set the camera position in 3D space
	transform.origin = Vector3(-6, 3, 6)  # Position camera at x=-6, y=3, z=6
	
	# Point the camera to look at a specific point in the scene
	look_at(Vector3(0, 1, 0))  # Look at position x=0, y=1, z=0
	
	# Set the camera to use perspective projection 
	# (as opposed to orthographic projection)
	projection = Camera3D.PROJECTION_PERSPECTIVE
	
	# Set the field of view to 60 degrees
	# This controls how wide an area the camera captures
	fov = 60
