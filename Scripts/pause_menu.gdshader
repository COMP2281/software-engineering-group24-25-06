shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float lod: hint_range(0.0, 5) = 0.0;

void fragment() {
	vec4 colour = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	COLOR = colour;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
