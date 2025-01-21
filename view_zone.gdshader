shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
instance uniform float view_radius;
instance uniform float view_fov;
instance uniform float close_radius;
instance uniform float quad_size;
instance uniform vec3 instant_color : source_color = vec3(1.0, 0.0, 0.0);
instance uniform vec3 view_color : source_color = vec3(0.0, 1.0, 0.0);
instance uniform float alpha : hint_range(0.0, 1.0) = 0.3;
instance uniform float invisible_alpha : hint_range(0.0, 1.0) = 0.0;

const vec2 local_uv[] = { vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(1.0, 1.0), vec2(0.0, 1.0) };
varying vec2 LOCAL_UV;

void vertex() {
	// Called for every vertex the material is visible on.
	// POSITION = vec4(VERTEX.xyz, 1.0);
	LOCAL_UV = local_uv[VERTEX_ID];
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

	float scaled_view_radius = view_radius / quad_size;
	float scaled_close_radius = close_radius / quad_size;

	vec2 origin = vec2(0.5, 0.5);
	float origin_angle = 0.5 * PI;

	float dist = distance(UV, origin);
	float angle = -(atan(UV.y - origin.y, UV.x - origin.x) - origin_angle);

	// Checking if we're in the instant section
	float instant_multiplier = (sign(scaled_close_radius - dist) + 1.0) * 0.5;

	// Checking if we're in view section
	// Calculation is a bit overcomplicated because of ranges
	float relative_direction_angle = PI - abs(mod(abs(angle), 2.0 * PI) - PI);
	// If this is negative, we are outside the FOV, display black
	// If this is positive, display view_color
	float view_fov_multiplier = (sign(view_fov - relative_direction_angle) + 1.0) * 0.5;
	float view_dist_multiplier = (sign(scaled_view_radius - dist) + 1.0) * 0.5;
	// If both, prioritise instant_multiplier
	float view_multiplier = view_fov_multiplier * view_dist_multiplier * (1.0 - instant_multiplier);

	vec3 color = view_multiplier * view_color + instant_multiplier * instant_color;

	float any_color_multiplier = view_multiplier + instant_multiplier;

	ALBEDO.rgb = vec3(color);
	ALPHA = alpha * any_color_multiplier + invisible_alpha * (1.0 - any_color_multiplier);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
