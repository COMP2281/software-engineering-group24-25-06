shader_type canvas_item;

uniform sampler2D alpha_image : source_color;
uniform float alertness_level : hint_range(0.0, 1.0) = 0.2;
uniform vec3 background_color : source_color;

void vertex() {}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 sample_color = texture(alpha_image, UV);

	// Get UV distance to alertness_level
	float uv_dist_sign = sign(UV.x - alertness_level);
	float default_multiplier = max(0.0, uv_dist_sign);
	float color_multiplier = abs(min(0.0, uv_dist_sign));
	
	// If uv_dist_sign < 0
	//	color it in
	
	// COLOR = sample_color
	// COLOR = (1.0 - sample_color.a) * red 

	COLOR = vec4(background_color.rgb * (1.0 - sample_color.a), color_multiplier) + sample_color;
}
