class_name Cosmetics
extends RefCounted

# Efeitos visuais vendidos na loja (moksha.com.br/loja). Nenhum mexe em dano,
# alcance, velocidade ou no que o jogador enxerga do perigo: só cor e brilho.
#   LÂMINAS  a cor do arco do golpe, do clarão e das faíscas ao bater
#   RASTROS  a cor das silhuetas da rolagem/mergulho e partículas ao correr
#   FILTROS  gradação de cor da tela inteira (modo do shader em PostFx)
# A conta diz o que o jogador tem (Meta.store_skins traz os ids); o que está
# em uso fica no legado (Meta.data["fx_blade" | "fx_trail" | "fx_filter"]).

const BLADES := {
	"lamina_brasa": {"title": "Corte de Brasa", "color": "ff7a2a", "spark": "ffd27a"},
	"lamina_geada": {"title": "Corte de Geada", "color": "9fe8ff", "spark": "f2fbff"},
	"lamina_vazio": {"title": "Corte do Vazio", "color": "8a4aff", "spark": "1a0a2e"},
	"lamina_ouro": {"title": "Corte Dourado", "color": "f2c14e", "spark": "fff2c0"},
	"lamina_sangue": {"title": "Corte de Sangue", "color": "d8263a", "spark": "ff8a8a"},
	"lamina_espectro": {"title": "Corte Espectral", "color": "6affc8", "spark": "e0fff4"},
}

# kind: como as partículas se movem ao correr ("sobe" = brasa, "cai" = neve/pétala, "brilha" = parada)
const TRAILS := {
	"rastro_brasa": {"title": "Rastro de Brasas", "color": "ff7a2a", "particle": "ffd27a", "kind": "sobe"},
	"rastro_geada": {"title": "Rastro de Geada", "color": "9fe8ff", "particle": "f2fbff", "kind": "cai"},
	"rastro_petalas": {"title": "Rastro de Pétalas", "color": "ff8ac8", "particle": "ffd0e8", "kind": "cai"},
	"rastro_vazio": {"title": "Rastro do Vazio", "color": "6a3aaa", "particle": "c8a8ff", "kind": "sobe"},
	"rastro_ouro": {"title": "Rastro Dourado", "color": "f2c14e", "particle": "fff2c0", "kind": "brilha"},
	"rastro_estrelas": {"title": "Rastro de Estrelas", "color": "4a6aff", "particle": "ffffff", "kind": "brilha"},
}

# mode: o número que o shader da tela entende (PostFx)
const FILTERS := {
	"filtro_pergaminho": {"title": "Pergaminho", "mode": 1, "color": "c8a070"},
	"filtro_luto": {"title": "Luto", "mode": 2, "color": "d8d8d8"},
	"filtro_fosforo": {"title": "Fósforo", "mode": 3, "color": "3aff6a"},
	"filtro_sonho": {"title": "Sonho", "mode": 4, "color": "c8a8ff"},
	"filtro_brasa": {"title": "Brasa", "mode": 5, "color": "ff8a3a"},
	"filtro_inverno": {"title": "Inverno", "mode": 6, "color": "9fd8ff"},
}

const KINDS := {
	"blade": {"key": "fx_blade", "list": BLADES, "title": "LÂMINAS", "detail": "A COR DO GOLPE."},
	"trail": {"key": "fx_trail", "list": TRAILS, "title": "RASTROS", "detail": "O QUE FICA PARA TRÁS QUANDO VOCÊ ROLA E CORRE."},
	"filter": {"key": "fx_filter", "list": FILTERS, "title": "FILTROS", "detail": "AS CORES DA TELA INTEIRA."},
}


static func owned(id: String) -> bool:
	return Meta.store_skins.has(id)


# O efeito em uso daquele tipo ({} = nenhum, ou o jogador não tem mais).
static func worn(kind: String) -> Dictionary:
	var k: Dictionary = KINDS[kind]
	var id := String(Meta.data.get(k["key"], ""))
	if id == "" or not owned(id) or not (k["list"] as Dictionary).has(id):
		return {}
	return k["list"][id]


static func worn_id(kind: String) -> String:
	return String(Meta.data.get(KINDS[kind]["key"], "")) if not worn(kind).is_empty() else ""


static func wear(kind: String, id: String) -> void:
	Meta.data[KINDS[kind]["key"]] = id
	Meta.save()


static func filter_mode() -> int:
	return int(worn("filter").get("mode", 0))
