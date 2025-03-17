extends Control

@onready var color_rect: ColorRect = $ColorRect;
@export var speed: float = 2.0;
# TODO: tolerance detached from shader tolerance meaning
@export var tolerance: float = 0.2;

var cursor_position: float = 0.0;
var direction: float = 1.0;
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var current_dot_position: float = 0.5;
var score: float = 0.0

# TODO: store last point for smooth transition?

func _input(event):
	# TODO: some way to check for "just pressed"
	if event is InputEventKey and event.pressed:
		print("Clicked!")
		
		if abs(cursor_position - current_dot_position) < tolerance:
			print("Good job!")
			score += 1.0
		else:
			score -= 1.0
			print("Bad job!")
		
		current_dot_position = rng.randf_range(0.0, 1.0)

func _process(delta: float) -> void:
	color_rect.material.set_shader_parameter("cursor", cursor_position)
	color_rect.material.set_shader_parameter("dot_position", current_dot_position)
	color_rect.material.set_shader_parameter("tolerance", tolerance)
	
	$Label.text = "(Press any button) Score: %.2f" % score
	
	cursor_position += delta * speed * direction
	
	if cursor_position > 1.0:
		direction = -1.0
	if cursor_position < 0.0:
		direction = 1.0
		
	
