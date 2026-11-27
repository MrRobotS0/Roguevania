// Névoa que corre na parte de baixo da tela (scripts/world/ambience.gd).
shader_type canvas_item;
uniform vec4 tint : source_color;
uniform vec2 screen = vec2(480.0, 270.0);
uniform float speed = 6.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0)); int y = int(mod(p.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[y * 4 + x]) / 16.0;
}
void fragment() {
	vec2 px = floor(UV * screen);
	vec2 p = px / vec2(90.0, 40.0);
	float n = noise(p + vec2(TIME * speed / 90.0, 0.0)) * 0.65 + noise(p * 2.1 - vec2(TIME * speed / 60.0, 0.0)) * 0.35;
	float band = smoothstep(0.35, 0.95, UV.y) * (1.0 - smoothstep(0.92, 1.0, UV.y) * 0.4);
	float k = n * band * tint.a * 2.6;
	COLOR = vec4(tint.rgb, smoothstep(0.0, 1.0, clamp(k, 0.0, 1.0)) * 0.42);
}
