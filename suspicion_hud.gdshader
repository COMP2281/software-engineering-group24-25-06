shader_type canvas_item;

uniform sampler2D alpha_image : source_color;
uniform float suspicion_level : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 sample_color = texture(alpha_image, UV);

	// Maybe cap at a level below 1.0, like 0.9, since hunting behaviour should begin
	// 	slightly below max
	COLOR = vec4(sample_color.rgb, sample_color.r - (1.0 - suspicion_level));
	// Go red when at max suspicion
	COLOR.gb = vec2(abs(sign(suspicion_level - 1.0)));
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
