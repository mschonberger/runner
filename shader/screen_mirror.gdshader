shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform bool flip_y = false;
uniform bool invert_colors = false;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Handle the gravity flip vertical mirroring
    if (flip_y) {
        uv.y = 1.0 - uv.y;
    }

    // Sample the screen colors
    vec4 tex_color = texture(screen_texture, uv);

    // Handle the color inversion
    if (invert_colors) {
        tex_color.rgb = 1.0 - tex_color.rgb;
    }

    COLOR = tex_color;
}