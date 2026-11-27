// Pós-processamento da tela inteira (scripts/ui/post_fx.gd): gradação de cor do domínio,
// aberração cromática, ondas de choque, ar quente, quadro de impacto, a morte do herói,
// filtro da loja e pontilhado de 1/255 contra degraus.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 shadow_tint = vec3(0.10, 0.08, 0.12);
uniform vec3 light_tint = vec3(1.0, 0.95, 0.85);
uniform float grade = 1.0;
uniform float gamma = 0.95;          // abaixo de 1 abre os meios-tons (domínio escuro)
uniform float curve = 0.30;          // quanto do S de contraste entra
uniform float saturation = 1.10;
uniform float aberration = 0.0;      // em pixels da tela do jogo
uniform vec2 px_size = vec2(0.00208, 0.0037);
uniform vec4 wave0 = vec4(0.5, 0.5, -1.0, 0.0);   // centro (uv), raio (uv no eixo y), força
uniform vec4 wave1 = vec4(0.5, 0.5, -1.0, 0.0);
uniform vec4 heat0 = vec4(0.5, 0.5, 0.0, 0.0);   // fogo: centro (uv), raio (uv no eixo y), força em pixels do jogo
uniform vec4 heat1 = vec4(0.5, 0.5, 0.0, 0.0);
uniform float impact = 0.0;          // quadro de impacto: 0 a 1, por dois quadros
uniform float death = 0.0;           // morte do herói: 0 (vivo) a 1 (a tela fechou)
uniform vec2 death_at = vec2(0.5);   // onde ele está (uv)
uniform float aspect = 1.7778;
uniform float time = 0.0;
uniform float breathe = 0.0;
uniform int filter_mode = 0;

vec3 store_filter(vec3 c, vec2 frag) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	if (filter_mode == 1) {          // Pergaminho: sépia
		return mix(c, vec3(l) * vec3(1.08, 0.9, 0.66) + vec3(0.05, 0.025, 0.0), 0.85);
	} else if (filter_mode == 2) {   // Luto: preto e branco duro, só o vermelho sobrevive
		float g = smoothstep(0.04, 0.92, l);
		float red = clamp((c.r - max(c.g, c.b) * 2.2) * 4.0, 0.0, 1.0);
		return mix(vec3(g), c, red);
	} else if (filter_mode == 3) {   // Fósforo: monitor verde com linhas
		float scan = 0.82 + 0.18 * step(1.0, mod(frag.y, 3.0));
		return (vec3(0.12, 1.0, 0.38) * pow(l, 0.9) * 1.15 + vec3(0.0, 0.035, 0.012)) * scan;
	} else if (filter_mode == 4) {   // Sonho: sombras lilás, luzes ciano, tudo mais leve
		vec3 duo = mix(vec3(0.32, 0.18, 0.46), vec3(0.78, 1.0, 0.96), l);
		return mix(c, duo, 0.55) * 0.92 + 0.06;
	} else if (filter_mode == 5) {   // Brasa: duotom quente
		return mix(c, mix(vec3(0.14, 0.02, 0.05), vec3(1.0, 0.78, 0.36), l), 0.7);
	} else if (filter_mode == 6) {   // Inverno: duotom frio
		return mix(c, mix(vec3(0.03, 0.06, 0.15), vec3(0.86, 0.95, 1.0), l), 0.65);
	}
	return c;
}

vec2 wave_offset(vec2 uv, vec4 w) {
	if (w.z < 0.0 || w.w <= 0.0) {
		return vec2(0.0);
	}
	vec2 d = uv - w.xy;
	d.x *= aspect;
	float dist = length(d);
	float ring = 1.0 - smoothstep(0.0, 0.045, abs(dist - w.z));
	if (dist < 0.0001) {
		return vec2(0.0);
	}
	vec2 dir = d / dist;
	dir.x /= aspect;
	return dir * ring * w.w;
}

// Ar quente sobre o fogo: numa coluna que sobe da chama, as linhas da tela escorregam
// para os lados em onda. É o truque de varredura dos jogos de 16 bits: o desvio é sempre
// de pixels inteiros do jogo e igual na linha toda, então a arte treme mas não borra.
float heat_shift(vec2 uv, vec4 h) {
	if (h.w <= 0.0) {
		return 0.0;
	}
	vec2 d = uv - h.xy;
	d.x *= aspect;
	float side = 1.0 - smoothstep(h.z * 0.25, h.z * 0.7, abs(d.x));
	float up = smoothstep(-h.z * 2.2, -h.z * 0.2, d.y) * (1.0 - step(h.z * 0.1, d.y));
	float row = floor(uv.y / px_size.y);
	float wave = sin(row * 0.85 - time * 9.0) + 0.5 * sin(row * 0.37 + time * 5.0);
	return floor(wave * side * up * h.w + 0.5) * px_size.x;
}

float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[i]) / 16.0 - 0.5;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += heat_shift(uv, heat0) + heat_shift(uv, heat1);
	uv -= wave_offset(uv, wave0);
	uv -= wave_offset(uv, wave1);
	vec3 c;
	if (aberration > 0.01) {
		vec2 from_center = uv - vec2(0.5);
		vec2 shift = from_center * aberration * px_size * 2.0;
		c.r = texture(screen_tex, uv + shift).r;
		c.g = texture(screen_tex, uv).g;
		c.b = texture(screen_tex, uv - shift).b;
	} else {
		c = texture(screen_tex, uv).rgb;
	}
	vec3 base = c;
	// Curva de tons. O contraste linear em volta de 0,5 escurecia tudo o que estava
	// abaixo do meio (num domínio escuro, a tela inteira). A gama abre os meios-tons
	// e o S dá o contraste segurando o preto e o branco onde estão.
	c = pow(max(c, vec3(0.0)), vec3(gamma));
	c = mix(c, c * c * (3.0 - 2.0 * c), curve);
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	// tons divididos: sombra puxa para o céu, luz para o sol
	float k = smoothstep(0.0, 1.0, l);
	c += shadow_tint * (1.0 - k) * 0.32;
	c *= mix(vec3(1.0), light_tint, k * 0.45);
	// respiração: luz quente bem lenta vinda de cima
	float glow = (1.0 - SCREEN_UV.y) * (0.5 + 0.5 * sin(time * 0.35)) * breathe;
	c += light_tint * glow * 0.035;
	c = mix(base, c, grade);
	// Quadro de impacto: no golpe que para o jogo a tela vira luz e sombra chapadas por
	// dois quadros, como no quadro-chave de uma animação de luta.
	if (impact > 0.0) {
		float hard = smoothstep(0.28, 0.52, dot(c, vec3(0.299, 0.587, 0.114)));
		c = mix(c, mix(vec3(0.05, 0.03, 0.07), vec3(1.0, 0.96, 0.88), hard), impact);
	}
	// Morte do herói: a cor escorre e um círculo fecha em volta dele, em degraus de
	// pixel do jogo. O tempo do jogo não muda.
	if (death > 0.0) {
		float grey = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, vec3(grey) * vec3(1.06, 0.93, 0.9), smoothstep(0.0, 0.45, death) * 0.85);
		vec2 d = (floor(SCREEN_UV / px_size) + 0.5) * px_size - death_at;
		d.x *= aspect;
		float radius = mix(1.5, 0.17, smoothstep(0.2, 1.0, death));
		c *= 1.0 - step(radius, length(d)) * 0.94;
	}
	c = store_filter(c, FRAGCOORD.xy);
	c += bayer(FRAGCOORD.xy) / 255.0;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
