// Corpo do herói e dos inimigos (Depth.body_material).
//
// Linha de luz no contorno: 1 pixel aceso na borda de fora do desenho, do lado de
// onde vem a luz de contorno do domínio. É o que separa o personagem do cenário
// quando os dois têm a mesma cor (herói de capa vermelha na Forja).
//   Quem é borda de fora vem pronto do mapa de relevo: o alfa dele guarda, por pixel,
//   se é o primeiro da linha pela esquerda (16), pela direita (32) ou da coluna por
//   cima (64), somado a 128 (tools/gen_normais.py). Vão entre a capa e o braço não é
//   borda de fora, então não acende no meio do corpo.
// Aura: contorno de 1 pixel por FORA do desenho, que pulsa (elite de arte pronta, que
// não tem a cor do contorno na paleta para trocar).
//
// O relevo continua funcionando sozinho: o shader não mexe em NORMAL.
shader_type canvas_item;

uniform vec2 luz = vec2(-0.8, -0.6);                                   // para que lado está a luz de contorno (y negativo = em cima)
uniform vec4 contorno : source_color = vec4(1.0, 0.95, 0.85, 0.0);    // cor; o alfa é a força (0 desliga)
uniform vec4 aura : source_color = vec4(0.0);                          // cor do contorno de fora; alfa 0 = sem
varying vec4 tinta;

void vertex() {
	tinta = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (contorno.a > 0.0 && c.a > 0.5) {
		int code = int(texture(NORMAL_TEXTURE, UV).a * 255.0 + 0.5);
		// 128 + bandeiras em múltiplos de 16; qualquer outra coisa é textura sem bandeira
		if (code >= 128 && (code & 15) == 0) {
			float esq = float((code >> 4) & 1);
			float dir = float((code >> 5) & 1);
			float cima = float((code >> 6) & 1);
			// espelhado (flip_h): a esquerda do desenho é a direita da tela
			if (dFdx(UV.x) < 0.0) {
				float troca = esq;
				esq = dir;
				dir = troca;
			}
			float k = max(max(esq * max(-luz.x, 0.0), dir * max(luz.x, 0.0)), cima * max(-luz.y, 0.0));
			c.rgb = mix(c.rgb, contorno.rgb, clamp(k * contorno.a, 0.0, 1.0));
		}
	}
	if (aura.a > 0.0 && c.a < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float perto = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		if (perto > 0.5) {
			c = vec4(aura.rgb, aura.a * (0.72 + 0.28 * sin(TIME * 5.0)));
		}
	}
	COLOR = c * tinta;
}
