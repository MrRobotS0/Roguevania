extends Node

# A partida atual: em que andar está, a semente do mapa e o que o herói
# carrega de um andar para o outro. Morreu, acabou: tudo daqui é perdido
# (o que fica para sempre está no Meta).
#
# Rota: cada andar termina numa passagem (Vigia + altar de mutação), e a
# passagem mostra as saídas para os próximos andares possíveis.
#
#   Mar de Cinzas ─┬─ Salões do Último Inverno ─┬─ Trono do Imperador Cego
#                  └─ Forja Rubra (mais difícil) ┘

const STAGES := {
	"mar_de_cinzas": {"biome": "mar_de_cinzas", "kind": "gerada", "next": ["saloes", "forja_rubra"]},
	"saloes": {"biome": "saloes", "kind": "gerada", "next": ["trono"]},
	"forja_rubra": {"biome": "forja_rubra", "kind": "gerada", "next": ["trono"]},
	"trono": {"biome": "mar_de_cinzas", "kind": "chefe", "next": []},
}
const FIRST := "mar_de_cinzas"
const MAX_HEAT := 4

var seed_value := 0
var stage_id := FIRST
var in_passage := false
var path: Array[String] = []
var carry := {}
var time := 0.0
var stage_time := 0.0
var heat := 0              # Brasas do Deus: dificuldade escolhida no título
var active := false


func new_run(seed_override := -1, heat_level := 0) -> void:
	seed_value = seed_override if seed_override >= 0 else randi()
	stage_id = FIRST
	in_passage = false
	path = [FIRST]
	carry = {}
	time = 0.0
	stage_time = 0.0
	heat = clampi(heat_level, 0, MAX_HEAT)
	active = true


func current() -> Dictionary:
	var s: Dictionary = STAGES[stage_id].duplicate()
	s["id"] = stage_id
	if in_passage:
		s["kind"] = "passagem"
	return s


func next_options() -> Array:
	return STAGES[stage_id]["next"]


func stage_seed() -> int:
	return seed_value + path.size() * 7349


func enter_passage() -> void:
	in_passage = true


func go(dest: String) -> void:
	stage_id = dest
	in_passage = false
	path.append(dest)
	stage_time = 0.0


func _process(delta: float) -> void:
	if active and not get_tree().paused:
		time += delta
		stage_time += delta


# --- dificuldade ------------------------------------------------------------------

func enemy_hp_mult() -> float:
	return 1.0 + 0.4 * heat


func enemy_damage_mult() -> float:
	return 1.0 + 0.25 * heat


# --- o que passa de um andar para o outro ------------------------------------------

# Primeiro andar: kit inicial + bênçãos compradas.
func starter_kit(p: Player) -> void:
	p.weapons = [Gear.of(load("res://content/weapons/espada_cerimonial.tres")),
		Gear.of(load("res://content/weapons/arco_dunas.tres"))]
	p.skills = [Gear.of(load("res://content/skills/granada_cinzas.tres")), null]
	var flasks := Player.BASE_FLASKS
	if Meta.is_unlocked("calice_1"):
		flasks += 1
	if Meta.is_unlocked("calice_2"):
		flasks += 1
	if heat >= 2:
		flasks -= 1
	p.max_flasks = maxi(flasks, 1)
	p.flasks = p.max_flasks
	if Meta.is_unlocked("bencao_vigia"):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		p.levels[Combat.STATS[rng.randi_range(0, 2)]] += 1
	if Meta.is_unlocked("bolsa_inicial"):
		p.gold = 60
	p.recompute_max_hp()
	p.hp = p.max_hp


func save_player(p: Player) -> void:
	carry = {
		"hp": p.hp, "weapons": p.weapons.duplicate(), "skills": p.skills.duplicate(),
		"levels": p.levels.duplicate(), "flasks": p.flasks, "max_flasks": p.max_flasks,
		"essence": p.essence, "kills": p.kills, "gold": p.gold,
		"mutations": p.mutations.duplicate(), "blueprints": p.blueprints.duplicate(),
	}


func load_player(p: Player) -> void:
	if carry.is_empty():
		starter_kit(p)
		return
	p.weapons = carry["weapons"].duplicate()
	p.skills = carry["skills"].duplicate()
	p.levels = carry["levels"].duplicate()
	p.max_flasks = carry["max_flasks"]
	p.flasks = carry["flasks"]
	p.essence = carry["essence"]
	p.kills = carry["kills"]
	p.gold = carry.get("gold", 0)
	p.mutations.assign(carry.get("mutations", []))
	p.blueprints.assign(carry.get("blueprints", []))
	p.recompute_max_hp()
	p.hp = clampi(carry["hp"], 1, p.max_hp)
