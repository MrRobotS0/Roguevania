// Chão molhado (scripts/world/reflection.gd): espelha a tela já desenhada logo acima do retângulo.
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 tint = vec3(0.5, 0.8, 0.9);
uniform float strength = 0.35;
uniform float depth_px = 12.0;
uniform float time = 0.0;
uniform float face = 5.0;     // a face de cima do bloco (Room.TOP_FACE): o espelho começa acima dela
void fragment() {
	// pixels da tela por pixel do mundo (vertical): o retângulo tem depth_px de altura
	float per_uv = 1.0 / max(abs(dFdy(UV.y)), 1e-6);   // pixels da tela no retângulo todo
	float scale = per_uv / depth_px;
	float d = UV.y * depth_px;                         // px do mundo abaixo da linha
	float wx = SCREEN_UV.x / SCREEN_PIXEL_SIZE.x / scale;  // x em px do mundo (para a onda)
	// ondulação em pixel inteiro: mais forte longe da linha
	float wob = floor(sin(time * 2.1 + wx * 0.21 + d * 0.8) * (0.4 + d * 0.09) + 0.5);
	vec2 uv = SCREEN_UV;
	uv.y -= (2.0 * (floor(d) + 0.5) + face) * scale * SCREEN_PIXEL_SIZE.y;
	uv.x += wob * scale * SCREEN_PIXEL_SIZE.x;
	vec3 c = textureLod(screen_tex, clamp(uv, vec2(0.0), vec2(1.0)), 0.0).rgb;
	float fade = pow(1.0 - UV.y, 1.6) * strength * step(0.0, uv.y);
	// faixas de brilho que correm (a lâmina d'água pegando luz)
	float sheen = step(0.985, sin(wx * 0.07 - time * 0.9 + d * 0.15)) * 0.25 * (1.0 - UV.y);
	vec3 refl = mix(c, c * tint, 0.45) * 1.25;
	COLOR = vec4(refl + tint * sheen, fade + sheen * 0.5);
}
