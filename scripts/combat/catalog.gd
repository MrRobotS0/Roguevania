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
]

const SKILLS := [
	"res://content/skills/granada_cinzas.tres",
	"res://content/skills/egide_bronze.tres",
	"res://content/skills/lanca_vidro.tres",
	"res://content/skills/armadilha_laminas.tres",
	"res://content/skills/torreta_vidro.tres",
	"res://content/skills/espirito_cinza.tres",
	"res://content/skills/corrente_ferreiro.tres",
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
}

const STAGE_NAMES := {
	"mar_de_cinzas": "O Mar de Cinzas",
	"saloes": "Os Salões do Último Inverno",
	"forja_rubra": "A Forja Rubra",
	"trono": "O Trono do Imperador Cego",
}

const STAGE_HINTS := {
	"saloes": "GELO E LOBOS · MAIS CALMO",
	"forja_rubra": "FOGO E FERRO · MAIS PERIGOSO, PAGA MELHOR",
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
