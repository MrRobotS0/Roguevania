class_name Catalog
extends RefCounted

# Lista oficial do que existe no jogo. Arma ou habilidade nova: criar o
# .tres e acrescentar o caminho aqui.

const WEAPONS := [
	"res://content/weapons/espada_cerimonial.tres",
	"res://content/weapons/arco_dunas.tres",
	"res://content/weapons/lanca_peregrino.tres",
	"res://content/weapons/machado_carrasco.tres",
	"res://content/weapons/arco_brasa.tres",
	"res://content/weapons/adagas_gemeas.tres",
	"res://content/weapons/martelo_forja.tres",
	"res://content/weapons/arco_inverno.tres",
	"res://content/weapons/chicote_espinhos.tres",
	"res://content/weapons/foice_inverno.tres",
	"res://content/weapons/punhos_bronze.tres",
	"res://content/weapons/besta_carcosa.tres",
	"res://content/weapons/cetro_astronomo.tres",
]

const SKILLS := [
	"res://content/skills/granada_cinzas.tres",
	"res://content/skills/egide_bronze.tres",
	"res://content/skills/lanca_vidro.tres",
	"res://content/skills/armadilha_laminas.tres",
	"res://content/skills/torreta_vidro.tres",
	"res://content/skills/espirito_cinza.tres",
	"res://content/skills/corrente_ferreiro.tres",
	"res://content/skills/sino_carcosa.tres",
	"res://content/skills/raiz_viva.tres",
	"res://content/skills/estrela_cadente.tres",
]

# Afixos: modificadores sorteados nas armas que caem (0 a 2 por arma).
const AFFIXES := {
	"brasa": {"title": "de Brasa", "detail": "GOLPES QUEIMAM"},
	"geada": {"title": "da Geada", "detail": "25% DE ATORDOAR"},
	"vampira": {"title": "Vampira", "detail": "CADA ACERTO CURA 1"},
	"explosiva": {"title": "Explosiva", "detail": "CRÍTICO EXPLODE EM VOLTA"},
	"afiada": {"title": "Afiada", "detail": "+15% DE DANO"},
	"ligeira": {"title": "Ligeira", "detail": "GOLPES 20% MAIS RÁPIDOS"},
	"carrasca": {"title": "Carrasca", "detail": "+50% EM QUEM TEM MENOS DE 30% DE VIDA"},
	"eco": {"title": "do Eco", "detail": "20% DE ACERTAR DUAS VEZES"},
}

const SKINS := [
	"res://content/skins/andarilho.tres",
	"res://content/skins/manto_cinza.tres",
	"res://content/skins/herdeiro_vesper.tres",
	"res://content/skins/casca_vidro.tres",
	"res://content/skins/olhos_fechados.tres",
	"res://content/skins/saco_penitente.tres",
]

const BIOMES := {
	"mar_de_cinzas": "res://content/biomes/mar_de_cinzas/biome.tres",
	"saloes": "res://content/biomes/saloes/biome.tres",
	"forja_rubra": "res://content/biomes/forja_rubra/biome.tres",
	"torre_babel": "res://content/biomes/torre_babel/biome.tres",
	"jardim_primordial": "res://content/biomes/jardim_primordial/biome.tres",
	"carcosa": "res://content/biomes/carcosa/biome.tres",
	"observatorio": "res://content/biomes/observatorio/biome.tres",
	"necropole": "res://content/biomes/necropole/biome.tres",
	"catedral": "res://content/biomes/catedral/biome.tres",
	"ventre": "res://content/biomes/ventre/biome.tres",
	"penhascos": "res://content/biomes/penhascos/biome.tres",
	"cavernas": "res://content/biomes/cavernas/biome.tres",
	"bosque": "res://content/biomes/bosque/biome.tres",
}

const STAGE_NAMES := {
	"mar_de_cinzas": "O Mar de Cinzas",
	"saloes": "Os Salões do Último Inverno",
	"forja_rubra": "A Forja Rubra",
	"lobo": "A Toca do Lobo da Longa Noite",
	"colosso": "A Bigorna do Colosso",
	"torre_babel": "A Torre de Babel",
	"jardim_primordial": "O Jardim Primordial",
	"arquiteto": "O Topo da Torre",
	"mae_raiz": "O Coração do Jardim",
	"carcosa": "Carcosa",
	"observatorio": "O Observatório Celeste",
	"rei_sem_rosto": "O Salão do Rei sem Rosto",
	"astronomo": "A Cúpula do Último Astrônomo",
	"necropole": "A Necrópole",
	"rei_esquecido": "A Cripta do Rei Esquecido",
	"catedral": "A Catedral Submersa",
	"o_que_responde": "O Altar do Que Responde",
	"ventre": "O Ventre",
	"insaciavel": "A Goela do Insaciável",
	"penhascos": "Os Penhascos do Sonho",
	"dragao_sonhado": "O Ninho do Dragão Sonhado",
	"cavernas": "As Cavernas Fundas",
	"serpe": "O Fundo da Serpe",
	"bosque": "O Bosque Errante",
	"raposa": "A Clareira da Raposa",
	"trono": "O Trono do Imperador Cego",
}

const STAGE_HINTS := {
	"saloes": "GELO E LOBOS · MAIS CALMO",
	"forja_rubra": "FOGO E FERRO · MAIS PERIGOSO, PAGA MELHOR",
	"torre_babel": "GÁRGULAS E ESCRIBAS · VERTICAL",
	"jardim_primordial": "FERAS E ESPINHOS · TUDO CRESCE",
	"carcosa": "MÁSCARAS QUE SOMEM · O MAIS ESTRANHO",
	"observatorio": "AUTÔMATOS E ESTRELAS · O MAIS ABERTO",
	"necropole": "MORTOS QUE LEMBRAM · O MAIS SOMBRIO",
	"catedral": "ÁGUA E PRECES · CHEIO DE ATIRADORES",
	"ventre": "CARNE VIVA · O MAIS BRUTO",
	"penhascos": "SONHO E VENTO · MUITOS VÃOS",
	"cavernas": "ESCURO E FENDAS · O MAIS FECHADO",
	"bosque": "ESTRADA SEM FIM · O MAIS RÁPIDO",
	"trono": "O FIM DA JORNADA",
}

# Mutações: bônus de uma partida só, escolhidos nas passagens (até 3).
const MUTATIONS := [
	{"id": "sangue_quente", "title": "Sangue Quente", "detail": "CADA ABATE CURA 3% DA VIDA"},
	{"id": "pes_leves", "title": "Pés Leves", "detail": "ROLA DE NOVO SEM ESPERAR"},
	{"id": "polvora", "title": "Pólvora Seca", "detail": "HABILIDADES RECARREGAM 35% MAIS RÁPIDO"},
	{"id": "vinganca", "title": "Vingança", "detail": "+40% DE DANO POR 3 S DEPOIS DE APANHAR"},
	{"id": "frieza", "title": "Frieza", "detail": "CRÍTICOS CAUSAM +25% DE DANO"},
	{"id": "lamina_plena", "title": "Lâmina Plena", "detail": "+20% DE DANO COM A VIDA ACIMA DE 80%"},
	{"id": "colecionador", "title": "Colecionador", "detail": "+50% DE ESSÊNCIA E OURO DOS INIMIGOS"},
	{"id": "folego", "title": "Fôlego", "detail": "+1 FRASCO DE CURA NESTA PARTIDA"},
	{"id": "couraca", "title": "Couraça de Escória", "detail": "AO APANHAR, ESTILHAÇOS ACERTAM QUEM ESTIVER COLADO"},
	{"id": "ultimo_folego", "title": "Teimosia", "detail": "UMA VEZ POR ANDAR, FICA COM 1 DE VIDA EM VEZ DE MORRER"},
	{"id": "sede", "title": "Sede de Batalha", "detail": "CADA ABATE ADIANTA AS HABILIDADES EM 1 S"},
	{"id": "passo_ligeiro", "title": "Passo do Lobo", "detail": "ROLAR ATRAVÉS DE UM GOLPE: O PRÓXIMO ATAQUE É CRÍTICO"},
	{"id": "barganha", "title": "Língua de Mercador", "detail": "TUDO NO MERCADOR CUSTA 30% MENOS"},
	{"id": "rastro_brasa", "title": "Rastro de Brasa", "detail": "ROLAR ATRAVÉS DE UM INIMIGO O INCENDEIA"},
]
const MAX_MUTATIONS := 3

# Melhorias permanentes compradas com Essência na Vigia (além das armas).
const BLESSINGS := [
	{"id": "calice_1", "title": "Cálice Extra", "cost": 50, "detail": "+1 FRASCO DE CURA EM TODA PARTIDA"},
	{"id": "bencao_vigia", "title": "Bênção da Vigia", "cost": 40, "detail": "COMEÇA COM +1 NUM ATRIBUTO AO ACASO"},
	{"id": "calice_2", "title": "Segundo Cálice", "cost": 110, "detail": "+1 FRASCO DE CURA (REQUER O PRIMEIRO)", "needs": "calice_1"},
	{"id": "bolsa_inicial", "title": "Bolsa de Viagem", "cost": 45, "detail": "COMEÇA A PARTIDA COM 60 DE OURO"},
]


static func all_gear() -> Array[Resource]:
	var out: Array[Resource] = []
	for p in WEAPONS + SKILLS:
		out.append(load(p))
	return out


static func find(id: String) -> Resource:
	for r in all_gear():
		if r.id == id:
			return r
	return null


static func unlocked_pool() -> Array[Resource]:
	var out: Array[Resource] = []
	for r in all_gear():
		if Meta.has_gear(r):
			out.append(r)
	return out


static func random_gear(rng: RandomNumberGenerator, tier: int, exclude: Array = []) -> Gear:
	var pool := unlocked_pool()
	var options: Array[Resource] = []
	for r in pool:
		if not exclude.has(r.id):
			options.append(r)
	if options.is_empty():
		options = pool
	var pick: Resource = options[rng.randi_range(0, options.size() - 1)]
	var bump := 1 if rng.randf() < 0.3 else 0
	var g := Gear.of(pick, tier + bump)
	if g.is_weapon():
		var roll := rng.randf() - 0.08 * tier
		var count := 0 if roll > 0.45 else (1 if roll > 0.08 else 2)
		var keys := AFFIXES.keys()
		for i in count:
			var a: String = keys[rng.randi_range(0, keys.size() - 1)]
			if not g.affixes.has(a):
				g.affixes.append(a)
	return g


static func biome(id: String) -> BiomeData:
	return load(BIOMES[id])


static func skins() -> Array[SkinData]:
	var out: Array[SkinData] = []
	for p in SKINS:
		out.append(load(p))
	return out


static func skin(id: String) -> SkinData:
	for s in skins():
		if s.id == id:
			return s
	return load(SKINS[0])


# Itens trancados cuja planta ainda não foi achada (o que pode cair dos inimigos).
static func unknown_blueprints(carrying: Array = []) -> Array[Resource]:
	var out: Array[Resource] = []
	for r in all_gear():
		if r.starter or Meta.is_unlocked(r.id) or Meta.knows(r.id) or carrying.has(r.id):
			continue
		out.append(r)
	return out


static func mutation(id: String) -> Dictionary:
	for m: Dictionary in MUTATIONS:
		if m["id"] == id:
			return m
	return {}
