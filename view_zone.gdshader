shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
instance uniform float view_radius;
instance uniform float view_fov;
instance uniform float view_direction;
instance uniform float close_radius;
instance uniform float quad_size;
instance uniform vec3 inner_color : source_color = vec3(0.1, 0.6, 0.8);
instance uniform float frequency = 0.5;
instance uniform float num_waves = 16.0;

const vec2 local_uv[] = { vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 1.0), vec2(0.0, 1.0) };
varying vec2 LOCAL_UV;

void vertex() {
	// POSITION = vec4(VERTEX.xyz, 1.0);
	LOCAL_UV = local_uv[VERTEX_ID];
}

// Super common 2D white noise function
vec2 random_point(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

// Simple pseudo-random noise, sample a high-frequency sin-wave and take less significant values of the sin-wave
float random_float(float x) {
	return fract(sin(x * 48142.1858151) * 43758.5453123);
}

// Combined worley-voronoi noise
//	x: worley noise
//	yz: voronoi noise (coordinates of random point)
//  TODO: remove w, not particularly useful other than
//		strict edge detection
vec4 voronoi(vec2 uv) {
	float density = 4.0;
	
	float angle = fract(TIME * 0.1) * 2.0 * PI;
	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	
	mat2 rot_matrix;
	rot_matrix[0] = vec2(cos_angle, -sin_angle);
	rot_matrix[1] = vec2(sin_angle, cos_angle);
	
	// Index of lattice point
	vec2 current_lattice = floor(uv * density);
	// Position relative to lattice point
	vec2 relative_pos = fract(uv * density);
	
	vec4 result = vec4(10.0, 0.0, 0.0, 11.0);
	
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 lattice_offset = vec2(float(x), float(y));
			vec2 random = random_point(current_lattice + lattice_offset);
			random -= vec2(0.5, 0.5);
			random *= rot_matrix;
			random += vec2(0.5, 0.5);
			
			float dist = distance(lattice_offset + random, relative_pos);
			
			if (dist < result.x) {
				result.w = result.x;
				result.x = dist;
				result.yz = random;
			} else if (dist < result.w) {
				result.w = dist;
			}
		}
	}
	
	return result;
}

// Calculate distance to border for every coordinate
float scanner_effect(vec2 uv, float time) {
	vec2 origin = vec2(0.5, 0.5);
	float dist = distance(uv, origin);
	//vec2 vec = uv - origin;
	//float dist = pow(pow(abs(vec.x), 1.5) + pow(abs(vec.y), 1.5), 1.0/1.5);
	float sample_point = dist - fract(time * frequency);
	float sin_frequency = 2.0 * num_waves;
	
	float sample = (sin(sin_frequency * sample_point) + 1.0) * 0.5;
	// Reduce band size
	sample = pow(sample, 1.5);
	// Quadratic distance fall-off
	float distance_fade = max(0.0, 1.0 - 4.0 * dist * dist);
	
	return sample * distance_fade;
}

vec4 sample_point(vec2 uv) {
	vec2 origin = vec2(0.5, 0.5);
	float origin_angle = 0.5 * PI;
	
	float scaled_view_radius = view_radius / quad_size;
	float scaled_close_radius = close_radius / quad_size;

	float dist = distance(uv, origin);
	float angle = -(atan(uv.y - origin.y, uv.x - origin.x) - origin_angle);
	float dist_close_border = abs(dist - scaled_close_radius);
	float dist_view_border = abs(dist - scaled_view_radius);
	// Calculation is a bit overcomplicated because of ranges
	// TODO: can be simplified now?
	float relative_direction_angle = PI - abs(mod(abs(angle), 2.0 * PI) - PI);
	
	vec3 draw_color = inner_color;
	float draw_alpha = 0.0;
	
	float scanner_sample = scanner_effect(uv, TIME) * 0.8 + 0.1;
	vec4 voronoi = voronoi(uv) * 1.0;
	// TODO: distance fade should be applied to both of these?
	// TODO: distance fade that also applies to edges of view zone
	//	requires some maths to find vectors of edges, and project
	//	against those edges to find distance to edges
	
	//if ((voronoi.w - voronoi.x) > 0.2 / quad_size) {
		//scanner_sample = 0.0;
	//} else {
		//scanner_sample = 1.0;
	//}
	voronoi.w = pow(voronoi.x, 1.5);

	if (dist < scaled_close_radius) {
		draw_color = inner_color * (1.0 + scanner_sample * 0.3);
		draw_alpha = scanner_sample + voronoi.w;
	}
	
	if (dist < scaled_view_radius && relative_direction_angle < view_fov) {
		draw_color = inner_color * (1.0 + scanner_sample * 0.3);
		draw_alpha = scanner_sample + voronoi.w;
	}
	
	return vec4(draw_color.rgb, draw_alpha);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	// Normalised device coordinates
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	// Fit to screen dimensions
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	// Unproject from camera
	view.xyz /= view.w;
	float linear_depth = -view.z;

	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	// Unproject from camera
	vec3 world_position = world.xyz / world.w;

	vec4 color = sample_point(UV);
	
	ALBEDO.rgb = vec3(color.rgb);
	ALPHA = color.a;
}
