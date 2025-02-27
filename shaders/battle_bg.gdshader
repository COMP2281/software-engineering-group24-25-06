shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
// 32 images across
//	4096px -> 128px
uniform sampler2D matrix_texture;
uniform float cutoff_distance = 1000.0;
uniform vec3 tint : source_color;
uniform vec2 cell_size = vec2(64.0, 32.0);
uniform float fall_count : hint_range(0.0, 30.0, 1.0) = 14.0;
uniform float fall_density : hint_range(0.0, 30.0, 1.0) = 12.0;
uniform float resolution : hint_range(0.0, 128.0, 16.0) = 16.0;
// Baseline fall speed
uniform float fall_speed_base : hint_range(0.0, 2.0) = 0.3;
// Random modifier on fall speed (doesn't affect baseline)
uniform float fall_speed_modifier : hint_range(0.0, 1.0) = 0.1;
uniform float vertical_offset : hint_range(0.0, 10.0) = 1.0;
uniform float faller_length : hint_range(1.0, 50.0) = 20.0;
uniform float artefact_epsilon : hint_range(0.0, 1.0) = 0.1;
uniform float gamma_correction : hint_range(0.5, 3.0) = 2.0;

// Gold Noise ©2015 dcerisano@standard3d.com
// - based on the Golden Ratio
// - uniform normalized distribution
// - fastest static noise generator function (also runs at low precision)
// - use with indicated fractional seeding method. 
const float PHI = 1.61803398874989484820459;

float gold_noise(in vec2 xy){
       return fract(tan(distance(xy * PHI, xy) * 1.0) * xy.x);
}

// Can't find a source for this, there's so many PRNGs online, just found one that generates
//	a vec2
vec2 rand2(vec2 st){
  st = vec2( dot(st,vec2(127.1,311.7)),
             dot(st,vec2(269.5,183.3)) );
  return fract(sin(st) * 43758.5453123);
}

float fallerSpeed(float col, float faller) {
    return gold_noise(vec2(col, faller)) * fall_speed_modifier + fall_speed_base;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	// Normalized device coordinates
	//	-1.0 to 1.0 in XY, 0.0 to 1.0 in Z, for whatever reason...
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	// Unproject from camera
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 10);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  	vec3 world_position = world.xyz / world.w;
	
	vec2 pix = mod(SCREEN_UV, 1.0 / cell_size);
	vec2 cell_index = (SCREEN_UV - pix);
	vec2 cell_position = cell_index * cell_size;
	pix *= cell_size;
	
	// Take random character from texture
	//	use cell index as seed
	// TODO: understand this code
	float character_value = texture(matrix_texture, (floor(rand2(cell_index) * 4096.0) + pix) / resolution).x;
	
	// Cleanup some weird artefacts in the texture
	if (character_value < artefact_epsilon) { character_value = 0.0; }
	
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
	
	ALBEDO = vec3(character_value * b) * tint;
	ALPHA = float(linear_depth > cutoff_distance);
}
