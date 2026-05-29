shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(0.298, 1.0, 0.6, 1.0); // #4CFF99
uniform vec4 replace_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Dynamic Color
uniform float precision : hint_range(0.0, 0.1) = 0.05;

void fragment() {
	vec4 current_color = texture(TEXTURE, UV);
	
	// Check if the pixel color matches our placeholder color (#4CFF99)
	if (distance(current_color.rgb, target_color.rgb) < precision) {
		// Retain the original texture pixel's transparency (alpha) layer
		COLOR = vec4(replace_color.rgb, current_color.a);
	} else {
		COLOR = current_color;
	}
}