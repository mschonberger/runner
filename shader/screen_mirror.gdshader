shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform bool flip_y = false;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    if (flip_y) {
        uv.y = 1.0 - uv.y;
    }
    
    COLOR = texture(screen_texture, uv);
}