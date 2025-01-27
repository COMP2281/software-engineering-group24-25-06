class_name ViewzoneResource extends Resource

## How quickly a player will get detected, 1 / time
@export var detection_speed: float = 1.0
## The FOV of the enemy
@export_range(0.0, 180.0, 0.5, "radians_as_degrees") var fov: float = 75.0
## The close-range circle around which the player will be detected
@export var close_radius: float = 0.5
## The radius of the view cone of the enemy
@export var view_radius: float = 5.0
## How quickly suspicion decays from this enemy when not being seen
@export var decay_rate: float = 0.2
## The range at which this unit detects distractions
@export var distraction_range: float = 0.0
## The range at which this unit communicates with others
@export var communication_range: float = 20.0
