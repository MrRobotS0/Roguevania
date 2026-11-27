// Halo de chama (vela, lanterna, fornalha do cenário): soma luz em volta e tremula.
// Não é luz de verdade: não acende o chão, e por isso pode haver dezenas na tela.
// A fase do tremor sai da posição, para duas velas vizinhas não piscarem juntas.
shader_type canvas_item;
render_mode blend_add, unshaded;

varying float fase;

void vertex() {
	fase = MODEL_MATRIX[3].x * 0.37 + MODEL_MATRIX[3].y * 0.11;
}

void fragment() {
	COLOR.a *= 0.86 + 0.09 * sin(TIME * 9.0 + fase) + 0.05 * sin(TIME * 23.0 + fase * 1.7);
}
