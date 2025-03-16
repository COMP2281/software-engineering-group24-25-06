extends Control

@onready var color_rect: ColorRect = $ColorRect;
@export var speed: float = 2.0;

var cursor_position: float = 0.0;
var direction: float = 1.0;
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# TODO: use rng to generate goal point instead of in shader
# TODO: set tolerance through export
# TODO: check overlap between cursor and goal point
# TODO: store last point for smooth transition?

func _process(delta: float) -> void:
	color_rect.material.set_shader_parameter("cursor", cursor_position)
	
	cursor_position += delta * speed * direction;
	
	if cursor_position > 1.0:
		direction = -1.0
	if cursor_position < 0.0:
		direction = 1.0
