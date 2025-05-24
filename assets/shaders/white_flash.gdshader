shader_type canvas_item;

uniform float flash_amount = 0.0;
uniform vec4 flash_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    tex_color.rgb = mix(tex_color.rgb, flash_color.rgb, flash_amount);
    COLOR = vec4(tex_color.rgb, tex_color.a);
}