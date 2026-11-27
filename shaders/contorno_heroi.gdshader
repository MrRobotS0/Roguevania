// Linha de luz na borda do herói (scripts/actors/hero_volume.gd).
shader_type canvas_item;
render_mode unshaded;
uniform vec4 rim : source_color = vec4(1.0, 0.95, 0.85, 0.5);
uniform float side = 1.0;   // de que lado da folha a borda acende (+1 = direita)
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// só a borda de fora: o vão precisa ter 2 px (entre braço e corpo não acende)
	float e1 = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x * side, 0.0)).a;
	float e2 = texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x * side * 2.0, 0.0)).a;
	float up = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
	float up2 = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y * 2.0)).a;
	float solid = step(0.5, c.a);
	float k = solid * (1.0 - step(0.5, e1)) * (1.0 - step(0.5, e2));
	k = max(k, solid * (1.0 - step(0.5, up)) * (1.0 - step(0.5, up2)) * 0.4);
	COLOR = vec4(rim.rgb, rim.a * k * COLOR.a);
}
