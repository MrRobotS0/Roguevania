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
]

const SKILLS := [
	"res://content/skills/granada_cinzas.tres",
	"res://content/skills/egide_bronze.tres",
	"res://content/skills/lanca_vidro.tres",
]

const BIOMES := {
	"mar_de_cinzas": "res://content/biomes/mar_de_cinzas/biome.tres",
}

# Melhorias permanentes compradas com Essência na Vigia (além das armas).
const BLESSINGS := [
	{"id": "calice_1", "title": "Cálice Extra", "cost": 50, "detail": "+1 FRASCO DE CURA EM TODA PARTIDA"},
	{"id": "bencao_vigia", "title": "Bênção da Vigia", "cost": 40, "detail": "COMEÇA COM +1 NUM ATRIBUTO AO ACASO"},
	{"id": "calice_2", "title": "Segundo Cálice", "cost": 110, "detail": "+1 FRASCO DE CURA (REQUER O PRIMEIRO)", "needs": "calice_1"},
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
	return Gear.of(pick, tier + bump)


static func biome(id: String) -> BiomeData:
	return load(BIOMES[id])
