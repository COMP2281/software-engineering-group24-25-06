shader_type spatial;

uniform vec3 tint : source_color = vec3(1.0, 0.0, 0.0);
uniform float speed : hint_range(0.0, 100.0) = 1.0;
uniform float density : hint_range(1.0, 10.0) = 8.0;
uniform float random_influence : hint_range(0.0, 4.0) = 1.0;
uniform float gamma_correction : hint_range(1.0, 10.0) = 3.0;
uniform float value_multiplier : hint_range(1.0, 20.0) = 1.3;
uniform float traversal_distance : hint_range(0.0, 100.0) = 10.0;
uniform float traversal_speed : hint_range(0.0, 10.0) = 2.0;
uniform int octaves : hint_range(1, 10) = 3;

// Gold Noise ©2015 dcerisano@standard3d.com
// - based on the Golden Ratio
// - uniform normalized distribution
// - fastest static noise generator function (also runs at low precision)
// - use with indicated fractional seeding method. 
const float PHI = 1.61803398874989484820459;

float gold_noise(in vec2 xy, in float seed) {
	return fract(tan(distance(xy * PHI, xy) * seed) * xy.x);
}

// Random BS, hopefully its decent
vec2 gold_based_point(vec2 xy, float seed) {
	return fract(tan(distance(xy * PHI, xy) * seed) * xy);
}

// Rotate a vector by angle about a pivot point
vec2 rotate_vec2(float angle, vec2 vec, vec2 pivot) {
	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	
	mat2 rot_matrix;
	rot_matrix[0] = vec2(cos_angle, -sin_angle);
	rot_matrix[1] = vec2(sin_angle, cos_angle);
	
	vec -= pivot;
	vec *= rot_matrix;
	vec += pivot;
	
	return vec;
}

// Combined worley-voronoi noise
//	x: worley noise
//	yz: voronoi noise (offset of random point)
vec3 voronoi(vec2 uv, float seed) {
	float angle = fract(TIME * speed) * 2.0 * PI + sin(1843.5 * TIME) * random_influence;
	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	
	mat2 rot_matrix;
	rot_matrix[0] = vec2(cos_angle, -sin_angle);
	rot_matrix[1] = vec2(sin_angle, cos_angle);
	
	// Index of lattice point
	vec2 current_lattice = floor(uv * density);
	// Position relative to lattice point
	vec2 relative_pos = fract(uv * density);
	
	vec3 result = vec3(1.0 / 0.0, 0.0, 0.0);
	
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 lattice_offset = vec2(float(x), float(y));
			vec2 random = gold_based_point(current_lattice + lattice_offset, seed);
			
			random -= vec2(0.5, 0.5);
			random *= rot_matrix;
			random += vec2(0.5, 0.5);
			
			float dist = distance(lattice_offset + random, relative_pos);
			
			if (dist < result.x) {
				result.x = dist;
				result.yz = random;
			}
		}
	}
	
	return result;
}

// RGB <-> HSV conversion functions from
// https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float sample_fractal(vec2 uv, int n) {
	float total = 0.0;
	float amplitude = 4.0;
	float wavelength = 1.0;
	float total_amplitude = 0.0;
	float rate = 0.5;
	
	for (int i = 0; i < n; i++) {
		total_amplitude += amplitude;
		total += voronoi(uv * wavelength, float(i) + 1.0).x * amplitude;
		amplitude *= rate;
		wavelength /= rate;
	}
	
	return total / total_amplitude;
}

void fragment() {
	float sample = sample_fractal(UV + traversal_distance * fract(TIME * traversal_speed), octaves);
	sample = pow(sample, gamma_correction);
	
	vec3 hsv_color = rgb2hsv(tint);
	hsv_color.z *= value_multiplier;
	
	ALBEDO = hsv2rgb(hsv_color);
	ALPHA = sample;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
