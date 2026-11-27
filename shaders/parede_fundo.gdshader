// Parede de fundo (Room.draw_wall): a pedra do domínio recuada.
//
// Mais escura e com menos cor que o chão onde se pisa, puxada um fio para a cor
// da sombra do domínio, e escurecida no encontro com os blocos (oclusão): o canto
// entre o chão e a parede fecha, como num lugar de verdade.
//   A oclusão vem de uma textura com 1 pixel por bloco (Room._build_occlusion),
//   lida com filtro linear: o degradê entre um bloco e o vizinho sai de graça.
// Continua recebendo luz e relevo: o shader só mexe na cor.
shader_type canvas_item;

uniform sampler2D oclusao : filter_linear, repeat_disable;
uniform vec2 sala = vec2(1024.0);                        // tamanho da sala em pixels
uniform float tom = 0.5;                                 // quanto da luz da pedra sobra
uniform float sem_cor = 0.25;                            // quanto da cor a distância leva
uniform vec4 nevoa : source_color = vec4(0.0);           // cor da sombra do domínio; o alfa é a mistura
uniform float forca = 0.5;                               // 0 desliga a oclusão
varying vec2 lugar;

void vertex() {
	lugar = VERTEX / sala;
}

void fragment() {
	vec4 c = COLOR;
	c.rgb = mix(c.rgb, vec3(dot(c.rgb, vec3(0.299, 0.587, 0.114))), sem_cor) * tom;
	c.rgb = mix(c.rgb, nevoa.rgb, nevoa.a);
	if (forca > 0.0) {
		c.rgb *= 1.0 - texture(oclusao, lugar).r * forca;
	}
	COLOR = c;
}
