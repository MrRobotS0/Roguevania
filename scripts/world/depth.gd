class_name Depth
extends RefCounted

# Profundidade: a luz de cada domínio. Com os mapas de relevo
# (tools/gen_normais.py) uma luz que vem de um lado acende aquele lado de
# cada pedra, inimigo e do herói e deixa o outro na sombra: é isso que tira
# a pixel art do papel. A penumbra (CanvasModulate) desce um pouco para a
# luz ter de onde subir.
#
# Cada domínio: de onde vem a luz (graus; 0 = de cima, negativo = da
# esquerda, positivo = da direita, 180 = de baixo), cor, força e altura
# (0 = rasante, relevo forte; 1 = de frente, sem relevo).

const KEYS := {
	"mar_de_cinzas":     {"from": 38.0,   "color": Color("ffcf9a"), "energy": 0.62, "height": 0.5},
	"saloes":            {"from": -30.0,  "color": Color("a9c4ff"), "energy": 0.55, "height": 0.5},
	"forja_rubra":       {"from": 160.0,  "color": Color("ff8a50"), "energy": 0.50, "height": 0.5},
	"torre_babel":       {"from": 25.0,   "color": Color("ffe2a8"), "energy": 0.60, "height": 0.5},
	"jardim_primordial": {"from": -20.0,  "color": Color("d6ffa0"), "energy": 0.55, "height": 0.5},
	"carcosa":           {"from": 45.0,   "color": Color("ffe36b"), "energy": 0.58, "height": 0.5},
	"observatorio":      {"from": -40.0,  "color": Color("c9a8ff"), "energy": 0.58, "height": 0.5},
	"necropole":         {"from": -35.0,  "color": Color("9fe6d0"), "energy": 0.55, "height": 0.5},
	"catedral":          {"from": 10.0,   "color": Color("8fe8ff"), "energy": 0.60, "height": 0.5},
	"ventre":            {"from": 170.0,  "color": Color("ff8070"), "energy": 0.50, "height": 0.5},
	"penhascos":         {"from": 35.0,   "color": Color("ffc8f0"), "energy": 0.55, "height": 0.5},
	"cavernas":          {"from": -10.0,  "color": Color("8fb2ff"), "energy": 0.50, "height": 0.5},
	"bosque":            {"from": -60.0,  "color": Color("ffc070"), "energy": 0.66, "height": 0.5},
}
const DEFAULT := {"from": -30.0, "color": Color("ffe8c8"), "energy": 0.55, "height": 0.5}

# Máscaras de luz (CanvasItem.light_mask x Light2D.range_item_cull_mask).
# O herói carrega uma lamparina que acende o cenário em volta; se ela também o
# acendesse, somada à luz do domínio, ele estourava (a capa virava uma mancha e
# entrava no brilho). Por isso o corpo do herói fica num bit só dele: toda luz do
# mundo alcança MUNDO e HEROI, e a lamparina, só MUNDO.
const MUNDO := 1
const HEROI := 2
const PERSONAGENS := 4       # herói e inimigos: a luz própria dos personagens
const PAREDE := 8            # parede de fundo: só a luz do domínio, a do herói, braseiros e clarões
const SHADE_DIM := 0.86      # a penumbra fica mais escura: o resto vem da luz

# Tom de cada domínio. Medido nas fotos: em 7 dos 13 domínios mais de 40% da tela
# era quase preto (Forja e Ventre, 85%), e o fundo pintado saía mais claro e mais
# saturado que o chão onde se pisa. A regra agora é a de qualquer cena legível:
# fundo recuado (mais apagado e menos saturado), chão em meio-tom, personagens por
# cima de tudo.
#   penumbra: multiplica a luz ambiente do domínio (os mais escuros sobem)
#   fundo:    brilho do fundo pintado e quanto ele perde de cor (a camada de longe
#             perde tudo isso; a do meio, 60%; a de perto, 30%)
#   gama:     curva final da tela; abaixo de 1 abre os meios-tons sem lavar o preto
#   cor:      saturação final (os domínios de uma cor só ganham menos)
const TOM := {
	"mar_de_cinzas":     {"penumbra": 1.00, "fundo": [0.64, 0.28], "gama": 0.96, "cor": 1.10},
	"saloes":            {"penumbra": 1.12, "fundo": [0.62, 0.20], "gama": 0.90, "cor": 1.12},
	"forja_rubra":       {"penumbra": 1.40, "fundo": [0.74, 0.30], "gama": 0.80, "cor": 1.00},
	"necropole":         {"penumbra": 1.25, "fundo": [0.66, 0.22], "gama": 0.86, "cor": 1.12},
	"torre_babel":       {"penumbra": 1.05, "fundo": [0.62, 0.26], "gama": 0.94, "cor": 1.12},
	"jardim_primordial": {"penumbra": 1.15, "fundo": [0.62, 0.24], "gama": 0.90, "cor": 1.10},
	"catedral":          {"penumbra": 1.05, "fundo": [0.66, 0.20], "gama": 0.94, "cor": 1.12},
	"carcosa":           {"penumbra": 1.18, "fundo": [0.56, 0.38], "gama": 0.90, "cor": 1.00},
	"observatorio":      {"penumbra": 1.30, "fundo": [0.86, 0.18], "gama": 0.84, "cor": 1.12},
	"ventre":            {"penumbra": 1.35, "fundo": [0.82, 0.34], "gama": 0.82, "cor": 0.98},
	"penhascos":         {"penumbra": 1.00, "fundo": [0.62, 0.30], "gama": 0.98, "cor": 1.08},
	"cavernas":          {"penumbra": 1.50, "fundo": [0.74, 0.20], "gama": 0.84, "cor": 1.12},
	"bosque":            {"penumbra": 1.05, "fundo": [0.60, 0.30], "gama": 0.94, "cor": 1.08},
}
# Reflexo (especular) dos blocos de cada domínio que brilha: cor e abertura
# (0 a 1; quanto mais alto, menor e mais duro o reflexo). O mapa de onde brilha
# vem de tools/gen_especular.py; quem monta a textura é SpriteSheet.lit.
const GLOSS := {
	"tiles_saloes":       [Color(0.75, 0.9, 1.0), 0.42],
	"tiles_catedral":     [Color(0.6, 0.8, 1.0), 0.38],
	"tiles_cavernas":     [Color(0.7, 0.85, 1.0), 0.4],
	"tiles_ventre":       [Color(1.0, 0.7, 0.65), 0.34],
	"tiles_observatorio": [Color(0.85, 0.8, 1.0), 0.46],
	"tiles_forja_rubra":  [Color(1.0, 0.6, 0.35), 0.4],
}

const TOM_PADRAO := {"penumbra": 1.0, "fundo": [0.68, 0.2], "gama": 0.95, "cor": 1.1}


static func tom(biome_id: String) -> Dictionary:
	return TOM.get(biome_id, TOM_PADRAO)


static func key_of(biome_id: String) -> Dictionary:
	return KEYS.get(biome_id, DEFAULT)


# A luz principal do domínio. Fica no mundo (não segue a câmera: é direcional).
static func key_light(biome_id: String) -> DirectionalLight2D:
	var k := key_of(biome_id)
	var light := DirectionalLight2D.new()
	light.name = "LuzDoDominio"
	light.color = k["color"]
	light.energy = k["energy"]
	light.height = k["height"]
	# o padrão aponta para baixo (luz vinda de cima); girar muda de onde vem
	light.rotation_degrees = -float(k["from"])
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.range_item_cull_mask = MUNDO | HEROI | PAREDE
	return light


# Luz de contorno: fraca, rasante e do lado oposto ao da principal. Acende a
# borda de quem está de costas para a luz (o que dá a silhueta em volume).
static func rim_light(biome_id: String, sky: Dictionary) -> DirectionalLight2D:
	var k := key_of(biome_id)
	var light := DirectionalLight2D.new()
	light.name = "LuzDeContorno"
	light.color = Color(sky.get("glow", Color("b8c8ff"))).lerp(Color.WHITE, 0.3)
	light.energy = 0.32
	light.height = 0.08
	light.rotation_degrees = -(float(k["from"]) + 180.0)
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.range_item_cull_mask = MUNDO | HEROI
	return light


static func shadow_side(biome_id: String) -> float:
	var from := float(key_of(biome_id)["from"])
	return -1.0 if sin(deg_to_rad(from)) > 0.0 else 1.0


# Um piso de luz branca por baixo da cor do domínio: sem ele o tom fica bonito mas
# o que está na sombra some.
const FILL := 0.2


static func shade_color(base: Color, biome_id := "") -> Color:
	var k := SHADE_DIM * float(tom(biome_id)["penumbra"])
	return Color(minf(base.r * k + FILL, 1.0), minf(base.g * k + FILL, 1.0), minf(base.b * k + FILL, 1.0), 1.0)


# O material do corpo de um personagem: linha de luz no contorno, do lado oposto
# ao da luz do domínio e sempre vindo de cima (shaders/personagem.gdshader).
# `strength` 0 a 1. `aura` é o contorno de 1 pixel por fora do desenho (elite); vale em
# qualquer qualidade. Sem linha de luz nem aura, devolve null (desenho comum).
const BODY := preload("res://shaders/personagem.gdshader")


static func body_material(biome_id: String, sky: Dictionary, strength: float, aura := Color(0, 0, 0, 0)) -> ShaderMaterial:
	var rim := Graficos.on("contorno_luz")
	if not rim and aura.a <= 0.0:
		return null
	var m := ShaderMaterial.new()
	m.shader = BODY
	if rim:
		var from := float(key_of(biome_id)["from"])
		var side := -1.0 if sin(deg_to_rad(from)) > 0.0 else 1.0
		m.set_shader_parameter("luz", Vector2(side, -0.75).normalized())
		var tone: Color = Color(sky.get("glow", Color("b8c8ff"))).lerp(Color.WHITE, 0.55)
		m.set_shader_parameter("contorno", Color(tone.r, tone.g, tone.b, strength))
	if aura.a > 0.0:
		m.set_shader_parameter("aura", aura)
	return m


# A luz dos personagens: só o herói e os inimigos a recebem (máscara PERSONAGENS).
# De frente, fraca e quase branca: tira os corpos do tom do cenário, que é o que
# faz o herói vermelho aparecer num domínio vermelho.
#   É uma luz pontual do tamanho da sala, chapada e muito alta, e não uma direcional:
#   no renderer Compatibilidade a direcional ignora a máscara de itens (medido no
#   navegador: com uma luz verde "só dos personagens" o chão inteiro ficou verde).
static var _flat: ImageTexture


static func actor_light(room_size: Vector2) -> PointLight2D:
	if _flat == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_flat = ImageTexture.create_from_image(img)
	var span := maxf(maxf(room_size.x, room_size.y), 480.0)
	var light := PointLight2D.new()
	light.name = "LuzDosPersonagens"
	light.texture = _flat
	light.texture_scale = span / 4.0 + 64.0
	light.position = room_size * 0.5
	light.color = Color(1.0, 0.97, 0.92)
	light.energy = 0.26
	# bem acima do plano: chega quase de frente em qualquer ponto da sala
	light.height = span * 3.0
	light.range_item_cull_mask = PERSONAGENS
	return light
