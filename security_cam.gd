extends Node3D

# TODO: some of these variables shouldn't be here
@export var DETECTION_SPEED : float = 1.0;
@export var SUSPICION_LEVEL : float = 0.0;
@export var CURRENTLY_SEEING_PLAYER : bool = false;
@export var SUSPICION_DECAY_RATE : float = 0.2;

@export var viewzone_resource : Resource;

# TODO: should be externally determined
var stealth_modifier = 1.0;

# TODO: expose the view zone properties

func _process(delta: float) -> void:
	$ViewZone.VIEW_DIRECTION = global_rotation.y;
	$ViewZone.viewzone_resource = viewzone_resource;
	
	var detection_manifold : DetectionManifold = $ViewZone.in_detection_range(PlayerProperties.global_position);
	
	if detection_manifold.being_seen:
		var suspicion_delta : float = DETECTION_SPEED;
			
		suspicion_delta *= 1.0 / stealth_modifier;
			
		SUSPICION_LEVEL += suspicion_delta * delta;
		CURRENTLY_SEEING_PLAYER = true;
	else:
		SUSPICION_LEVEL -= SUSPICION_DECAY_RATE * delta;
		CURRENTLY_SEEING_PLAYER = false;
		
	SUSPICION_LEVEL = clamp(SUSPICION_LEVEL, 0.0, 1.0);
	PlayerProperties.ENEMY_TOP_SUSPICION = max(PlayerProperties.ENEMY_TOP_SUSPICION, SUSPICION_LEVEL);
	PlayerProperties.BEING_SEEN = PlayerProperties.BEING_SEEN or CURRENTLY_SEEING_PLAYER;
	PlayerProperties.WITHIN_CLOSE_RADIUS = PlayerProperties.WITHIN_CLOSE_RADIUS or detection_manifold.within_close_range;
