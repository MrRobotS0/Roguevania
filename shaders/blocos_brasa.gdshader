// O que emite luz nos blocos (Room.draw_emissive): metal em brasa e carne.
// O desenho vem de tools/gen_emissivo.py (só os pixels que emitem, com a força no
// alfa) e é somado por cima do bloco. Pulsa devagar, numa onda que atravessa a
// sala: a fase sai da posição, então vizinhos acendem um depois do outro.
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float forca = 0.55;          // brilho no pico
uniform float fundo = 0.35;          // quanto fica aceso no vale da onda (0 a 1)
uniform float ritmo = 1.3;
varying vec2 lugar;

void vertex() {
	lugar = VERTEX;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float onda = 0.5 + 0.5 * sin(TIME * ritmo - lugar.x * 0.03 + lugar.y * 0.017);
	COLOR = vec4(c.rgb, c.a * forca * mix(fundo, 1.0, onda));
}
