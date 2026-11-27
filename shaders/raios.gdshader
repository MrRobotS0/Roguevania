// Raios de luz do domínio (scripts/world/ambience.gd): leque que gira devagar a partir de `origin`.
shader_type canvas_item;
render_mode blend_add;
uniform vec4 tint : source_color;
uniform vec2 origin = vec2(0.7, -0.1);
uniform vec2 screen = vec2(480.0, 270.0);
float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0)); int y = int(mod(p.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[y * 4 + x]) / 16.0;
}
void fragment() {
	vec2 px = floor(UV * screen);
	vec2 d = px / screen - origin;
	d.x *= screen.x / screen.y;
	float a = atan(d.y, d.x);
	float r = pow(abs(sin(a * 9.0 + TIME * 0.12) * sin(a * 15.0 - TIME * 0.07)), 4.0);
	float fall = clamp(1.0 - length(d) * 0.75, 0.0, 1.0);
	float k = r * fall * tint.a * 2.2;
	// transparência lisa: o pontilhado (bayer) virava uma peneira de pixels na frente da arte
	COLOR = vec4(tint.rgb, clamp(k, 0.0, 1.0) * 0.32);
}
