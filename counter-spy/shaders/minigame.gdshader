shader_type canvas_item;

uniform vec3 tint : source_color;
uniform vec3 tint_selected: source_color;
uniform vec3 cursor_color: source_color;
uniform float dot_radius : hint_range(0.0, 0.5) = 0.01;
uniform float dot_luminesence : hint_range(0.0, 1.0) = 0.1;
uniform float dot_gamma : hint_range(0.0, 10.0) = 2.5;
uniform float dot_gamma_variance : hint_range(0.0, 5.0) = 2.0;
uniform float dot_gamma_varying_frequency : hint_range(0.0, 5.0) = 0.5; 
uniform float dot_count : hint_range(10.0, 30.0) = 20.0;
uniform float tolerance : hint_range(0.0, 5.0) = 2.0;
uniform float padding : hint_range(0.0, 0.5) = 0.1;
uniform float general_epsilon = 0.005;
uniform float row : hint_range(0.0, 10.0) = 0.0;
uniform float cursor : hint_range(0.0, 1.0) = 0.0;
uniform float squircle_power : hint_range(1.0, 10.0) = 3.0;
uniform float squircle_radius : hint_range(0.0, 1.0) = 0.3;
uniform float squircle_luminesence : hint_range(0.0, 1.0) = 0.2;
uniform float squircle_gamma : hint_range(0.0, 10.0) = 3.0;
uniform float squircle_stretch : hint_range(0.0, 1.0) = 0.8;

const float PHI = 1.61803398874989484820459;

float gold_noise(in vec2 xy, in float seed) {
	return fract(tan(distance(xy * PHI, xy) * seed) * xy.x);
}

float transform_01_range(float x) {
	return x * (1.0 - 2.0 * (padding + general_epsilon)) + padding + general_epsilon;
}

void fragment() {
	float alpha = 1.0;
	vec3 color = tint;
	
	float current_gamma = dot_gamma + dot_gamma_variance * sin(TIME * dot_gamma_varying_frequency + UV.x);
	
	// TODO: need some maths for aspect ratio
	
	// Calculate distance to closest dot
	//	partition based on dot count
	vec2 lattice_point = floor(UV * dot_count) / dot_count + vec2(1.0, 1.0) / dot_count * 0.5;
	lattice_point.y = 0.5;
	
	if (lattice_point.x < padding) { lattice_point.x = -1000.0; }
	if (lattice_point.x > (1.0 - padding)) { lattice_point.x = -1000.0; }
	
	float dist_to_lattice = distance(UV, lattice_point);
	// TODO: adjust for padding
	float rand_point = transform_01_range(gold_noise(vec2(row), 1.0));
	float rand_point_lattice = floor(rand_point * dot_count) / dot_count + 1.0 / dot_count * 0.5;
	
	if (abs(rand_point_lattice - lattice_point.x) < (1.0 / dot_count) * (tolerance + general_epsilon)) {
		color = tint_selected;
	}
	
	float v = 1.0 - dist_to_lattice / dot_radius;
	v += dot_luminesence;
	v = pow(v, current_gamma);
	v = clamp(v, 0.0, 1.0);
	
	vec2 cursor_position = vec2(transform_01_range(cursor), 0.5 + dot_radius * 2.0);
	
	// Squircle math?
	vec2 cursor_vector = UV - cursor_position;
	cursor_vector.x *= squircle_stretch;
	float squircle_distance = pow(pow(abs(cursor_vector.x), squircle_power) + pow(abs(cursor_vector.y), squircle_power), 1.0 / squircle_power);
	float cursor_v = 1.0 - squircle_distance / squircle_radius;
	cursor_v += squircle_luminesence;
	cursor_v = pow(cursor_v, squircle_gamma);
	cursor_v = clamp(cursor_v, 0.0, 1.0);
	
	COLOR = vec4(color * v + cursor_color.xyz * cursor_v, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
