// Uma camada do fundo pintado (scripts/world/back_layer.gd): balanço de vento, tremor de
// calor, ondulação de água, pulso de luz e a névoa da distância.
shader_type canvas_item;
uniform vec2 tex_size = vec2(480.0, 270.0);
uniform float sway = 0.0;        // px no alto da camada
uniform float sway_speed = 0.6;
uniform float heat = 0.0;        // px de tremor perto do chão
uniform float wave = 0.0;        // px da ondulação de água
uniform vec4 fog : source_color = vec4(0.0);
uniform float fog_amount = 0.0;
uniform float glow = 0.0;        // a camada inteira acende e apaga (pulso)
uniform float desat = 0.0;       // quanto da cor a distância leva embora
uniform float glow_speed = 0.5;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 uv = UV;
	float y = uv.y;
	float top = 1.0 - y;
	float off = sin(TIME * sway_speed + y * 7.0 + uv.x * 9.0) * sway * top * top;
	off += sin(TIME * 2.7 + y * 140.0) * heat * y * y;
	off += sin(TIME * 1.1 + y * 18.0 + uv.x * 3.0) * wave;
	float lift = sin(TIME * 0.9 + uv.x * 14.0) * wave * 0.6;
	uv.x += off / tex_size.x;
	uv.y += lift / tex_size.y;
	vec4 c = texture(TEXTURE, uv);
	c.rgb = mix(c.rgb, vec3(dot(c.rgb, vec3(0.299, 0.587, 0.114))), desat);
	c.rgb = mix(c.rgb, fog.rgb, fog_amount * mix(0.55, 1.0, y));
	c.rgb *= 1.0 + glow * (0.5 + 0.5 * sin(TIME * glow_speed + uv.x * 4.0));
	COLOR = c * tint;
}
