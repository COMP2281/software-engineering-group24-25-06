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
uniform float tolerance : hint_range(0.0, 10.0) = 2.0;
uniform float padding : hint_range(0.0, 0.5) = 0.1;
uniform float general_epsilon = 0.005;
uniform float row : hint_range(0.0, 10.0) = 0.0;
uniform float cursor : hint_range(0.0, 1.0) = 0.0;
uniform float dot_position : hint_range(0.0, 1.0) = 0.0;
uniform float squircle_power : hint_range(1.0, 10.0) = 3.0;
uniform float squircle_radius : hint_range(0.0, 1.0) = 0.3;
uniform float squircle_luminesence : hint_range(0.0, 1.0) = 0.2;
uniform float squircle_gamma : hint_range(0.0, 10.0) = 3.0;
uniform float squircle_stretch : hint_range(0.0, 1.0) = 0.8;

uniform sampler2D matrix_texture;
uniform vec3 matrix_tint : source_color;
uniform vec2 cell_size = vec2(128.0, 64.0);
uniform float fall_count : hint_range(0.0, 30.0, 1.0) = 16.0;
uniform float fall_density : hint_range(0.0, 30.0, 1.0) = 14.0;
uniform float resolution : hint_range(0.0, 128.0, 16.0) = 32.0;
// Baseline fall speed
uniform float fall_speed_base : hint_range(0.0, 2.0) = 0.1;
// Random modifier on fall speed (doesn't affect baseline)
uniform float fall_speed_modifier : hint_range(0.0, 1.0) = 0.16;
uniform float vertical_offset : hint_range(0.0, 10.0) = 1.0;
uniform float faller_length : hint_range(1.0, 50.0) = 20.0;
uniform float artefact_epsilon : hint_range(0.0, 1.0) = 0.1;
uniform float gamma_correction : hint_range(0.5, 3.0) = 1.4;
uniform float background_brightness : hint_range(0.0, 2.0) = 0.5;

uniform float vignette_radius : hint_range(0.0, 5.0) = 1.1;
uniform float vignette_strength : hint_range(-2.0, 2.0) = 0.03;

const float PHI = 1.61803398874989484820459;

float gold_noise(in vec2 xy, in float seed) {
	return fract(tan(distance(xy * PHI, xy) * seed) * xy.x);
}

// Can't find a source for this, there's so many PRNGs online, just found one that generates
//	a vec2
vec2 rand2(vec2 st){
  st = vec2( dot(st,vec2(127.1,311.7)),
             dot(st,vec2(269.5,183.3)) );
  return fract(sin(st) * 43758.5453123);
}

float fallerSpeed(float col, float faller) {
    return gold_noise(vec2(col, faller), 1.0) * fall_speed_modifier + fall_speed_base;
}

vec3 matrix_background(vec2 screen_uv) {
	vec2 pix = mod(screen_uv, 1.0 / cell_size);
	vec2 cell_index = (screen_uv - pix);
	vec2 cell_position = cell_index * cell_size;
	pix *= cell_size;
	
	// Take random character from texture
	//	use cell index as seed
	// TODO: understand this code
	float character_value = texture(matrix_texture, (floor(rand2(cell_index) * 16.0) + pix) / resolution).x;
	
	// Cleanup some weird artefacts in the texture
	// if (character_value < artefact_epsilon) { character_value = 0.0; }
	
	// Calculate value/light/effect intensity
	float b = 0.0;
	
	for (float i = 0.0; i < fall_count; i += 1.0) {
		// Calculate light of faller
		// TODO: understand this code
		float f = cell_position.y / faller_length + vertical_offset -
            mod((TIME + i * 3534.34) * fallerSpeed(cell_position.x, i), fall_density);
			
		if (f > 0.0 && f < 1.0) {
			b += f;
		}
	}
	
	b = pow(b, gamma_correction);
	
	float v = (1.0 - length((screen_uv - vec2(0.5, 0.5)) * 2.0) / vignette_radius);
	v = v * (1.0 - vignette_strength) + vignette_strength;
	v = clamp(v, 0.0, 1.0);
	
	return vec3(character_value * b * v * background_brightness) * matrix_tint;
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
	float rand_point = transform_01_range(dot_position);
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
	
	vec3 minigame_colour = color * v + cursor_color.xyz * cursor_v;
	vec3 bg_color = matrix_background(SCREEN_UV);
	
	COLOR = vec4(minigame_colour + bg_color, 1.0);
}
