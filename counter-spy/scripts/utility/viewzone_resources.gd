class_name ViewzoneResource extends Resource

## How quickly a player will get detected, 1 / time
@export var detection_speed: float = 0.5
## The FOV of the enemy
@export_range(0.0, 180.0, 0.5, "radians_as_degrees") var fov: float = 75.0
## The close-range circle around which the player will be detected
@export var close_radius: float = 0.5
## The radius of the view cone of the enemy
@export var view_radius: float = 5.0
## How quickly suspicion decays from this enemy when not being seen
@export var decay_rate: float = 0.1
# TODO: attach to hearing modifier?
## The range at which this unit communicates with others
@export var communication_range: float = 20.0
## Higher values signify this enemy can hear things from further away
@export var hearing_modifier: float = 1.0
