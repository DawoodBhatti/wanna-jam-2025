shader_type canvas_item;

uniform float border_size = 0.02; // relative to UV space
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 0.4);
uniform float fade : hint_range(0.0, 1.0) = 1.0; // 🔹 new fade control

void fragment() {
	vec2 uv = UV;
	if (uv.x < border_size || uv.x > 1.0 - border_size ||
	    uv.y < border_size || uv.y > 1.0 - border_size) {
		COLOR = border_color;
		COLOR.a *= fade; // apply fade to border
	} else {
		COLOR = texture(TEXTURE, uv);
		COLOR.a *= fade; // apply fade to main texture
	}
}