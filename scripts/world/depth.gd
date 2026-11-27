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
const SHADE_DIM := 0.86      # a penumbra fica mais escura: o resto vem da luz


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
	light.range_item_cull_mask = MUNDO | HEROI
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


static func shade_color(base: Color) -> Color:
	return Color(base.r * SHADE_DIM, base.g * SHADE_DIM, base.b * SHADE_DIM, 1.0)
