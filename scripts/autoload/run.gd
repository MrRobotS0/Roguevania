extends Node

# A partida atual: em que andar está, a semente do mapa e o que o herói
# carrega de um andar para o outro. Morreu, acabou: tudo daqui é perdido
# (o que fica para sempre está no Meta).
#
# Rota: cada domínio termina no guardião dele (arena de chefe); vencido o
# guardião, a passagem (Vigia + altar de mutação) mostra os próximos domínios.
#
#   Mar de Cinzas ─┬─ Salões ── Lobo da Longa Noite ─┬─ Torre de Babel ─── Arquiteto Mudo ─┬─ Carcosa ────── Rei sem Rosto ─┬─ Trono
#                  └─ Forja ─── Colosso da Bigorna ──┘  Jardim Primordial ─ Mãe-Raiz ───────┘  Observatório ── Último Astrônomo ┘

const STAGES := {
	"mar_de_cinzas": {"biome": "mar_de_cinzas", "kind": "gerada", "next": ["saloes", "forja_rubra", "necropole"]},
	"saloes": {"biome": "saloes", "kind": "gerada", "boss": "lobo"},
	"forja_rubra": {"biome": "forja_rubra", "kind": "gerada", "boss": "colosso"},
	"necropole": {"biome": "necropole", "kind": "gerada", "boss": "rei_esquecido"},
	"lobo": {"biome": "saloes", "kind": "chefe", "next": ["torre_babel", "jardim_primordial", "catedral"]},
	"colosso": {"biome": "forja_rubra", "kind": "chefe", "next": ["torre_babel", "jardim_primordial", "catedral"]},
	"rei_esquecido": {"biome": "necropole", "kind": "chefe", "next": ["torre_babel", "jardim_primordial", "catedral"]},
	"torre_babel": {"biome": "torre_babel", "kind": "gerada", "boss": "arquiteto"},
	"jardim_primordial": {"biome": "jardim_primordial", "kind": "gerada", "boss": "mae_raiz"},
	"catedral": {"biome": "catedral", "kind": "gerada", "boss": "o_que_responde"},
	"arquiteto": {"biome": "torre_babel", "kind": "chefe", "next": ["carcosa", "observatorio", "ventre"]},
	"mae_raiz": {"biome": "jardim_primordial", "kind": "chefe", "next": ["carcosa", "observatorio", "ventre"]},
	"o_que_responde": {"biome": "catedral", "kind": "chefe", "next": ["carcosa", "observatorio", "ventre"]},
	"carcosa": {"biome": "carcosa", "kind": "gerada", "boss": "rei_sem_rosto"},
	"observatorio": {"biome": "observatorio", "kind": "gerada", "boss": "astronomo"},
	"ventre": {"biome": "ventre", "kind": "gerada", "boss": "insaciavel"},
	"rei_sem_rosto": {"biome": "carcosa", "kind": "chefe", "next": ["penhascos", "cavernas", "bosque"]},
	"astronomo": {"biome": "observatorio", "kind": "chefe", "next": ["penhascos", "cavernas", "bosque"]},
	"insaciavel": {"biome": "ventre", "kind": "chefe", "next": ["penhascos", "cavernas", "bosque"]},
	"penhascos": {"biome": "penhascos", "kind": "gerada", "boss": "dragao_sonhado"},
	"cavernas": {"biome": "cavernas", "kind": "gerada", "boss": "serpe"},
	"bosque": {"biome": "bosque", "kind": "gerada", "boss": "raposa"},
	"dragao_sonhado": {"biome": "penhascos", "kind": "chefe", "next": ["trono"]},
	"serpe": {"biome": "cavernas", "kind": "chefe", "next": ["trono"]},
	"raposa": {"biome": "bosque", "kind": "chefe", "next": ["trono"]},
	"trono": {"biome": "mar_de_cinzas", "kind": "chefe", "next": []},
	"sala_dos_treze": {"biome": "observatorio", "kind": "sala", "next": []},
}
const FIRST := "mar_de_cinzas"
const HALL := "sala_dos_treze"
const MAX_HEAT := 4
const MAX_PLUS := 5

var seed_value := 0
var stage_id := FIRST
var in_passage := false
var path: Array[String] = []
var carry := {}
var time := 0.0
var stage_time := 0.0
var heat := 0              # Brasas do Deus: dificuldade escolhida no título
var plus := 0              # Novo Jogo+: em que ciclo está (0 = partida normal)
var stage_tier := 0        # profundidade do andar atual (inimigos ficam mais fortes)
var daily := ""            # data do desafio do dia ("" = partida normal)
var kills_by := {}         # título do inimigo -> abates nesta partida
var weapon_kills := {}     # id da arma/habilidade -> abates nesta partida
var killer := ""           # quem deu o último golpe no herói
var hurt_by := {}          # quem tirou quanta vida do herói nesta partida
var active := false


func new_run(seed_override := -1, heat_level := 0, plus_level := 0) -> void:
	seed_value = seed_override if seed_override >= 0 else randi()
	stage_id = FIRST
	in_passage = false
	path = [FIRST]
	carry = {}
	time = 0.0
	stage_time = 0.0
	heat = clampi(heat_level, 0, MAX_HEAT)
	plus = clampi(plus_level, 0, MAX_PLUS)
	stage_tier = 0
	daily = ""
	kills_by = {}
	weapon_kills = {}
	killer = ""
	hurt_by = {}
	active = true


func current() -> Dictionary:
	var s: Dictionary = STAGES[stage_id].duplicate()
	s["id"] = stage_id
	if in_passage:
		s["kind"] = "passagem"
	return s


func next_options() -> Array:
	return STAGES[stage_id].get("next", [])


func boss_of(id: String) -> String:
	return STAGES[id].get("boss", "")


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
	return (1.0 + 0.4 * heat) * (1.0 + 0.2 * stage_tier) * plus_hp_mult()


func enemy_damage_mult() -> float:
	return (1.0 + 0.25 * heat) * (1.0 + 0.1 * stage_tier) * (1.0 + 0.15 * plus)


func plus_hp_mult() -> float:
	return 1.0 + 0.25 * plus


# Novo Jogo+: os pesadelos rendem mais essência, e alguns vêm como elite.
func essence_mult() -> float:
	return 1.0 + 0.5 * mini(plus, 1)


func plus_elite_chance() -> float:
	return 0.09 + 0.03 * plus if plus > 0 else 0.0


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
	if plus > 0:
		flasks += 1
	p.max_flasks = maxi(flasks, 1)
	p.flasks = p.max_flasks
	if Meta.is_unlocked("bencao_vigia"):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		p.levels[Combat.STATS[rng.randi_range(0, 2)]] += 1
	if Meta.is_unlocked("bolsa_inicial"):
		p.gold = 60
	if plus > 0:
		# quem começa o Novo Jogo+ já sabe quem é
		p.weapons = [Gear.of(p.weapons[0].data, 1), Gear.of(p.weapons[1].data, 1)]
		for stat in Combat.STATS:
			p.levels[stat] += 1
		p.gold = maxi(p.gold, 100)
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


# --- partida salva ---------------------------------------------------------------------
# Todo andar começa gravando onde a partida está. Sair (ou fechar o jogo) e
# voltar recomeça daquele andar, com o que o herói tinha ao entrar nele.
# Morrer, vencer ou desistir apaga.

func snapshot() -> Dictionary:
	var c := carry.duplicate()
	if not c.is_empty():
		c["weapons"] = c["weapons"].map(_gear_out)
		c["skills"] = c["skills"].map(_gear_out)
	return {"seed": seed_value, "stage": stage_id, "in_passage": in_passage, "path": path.duplicate(),
		"time": time, "heat": heat, "daily": daily, "kills_by": kills_by.duplicate(),
		"weapon_kills": weapon_kills.duplicate(), "carry": c, "plus": plus}


func restore(s: Dictionary) -> void:
	new_run(int(s["seed"]), int(s["heat"]), int(s.get("plus", 0)))
	stage_id = s["stage"]
	in_passage = s["in_passage"]
	path.assign(s["path"])
	time = float(s["time"])
	daily = s["daily"]
	kills_by = s["kills_by"].duplicate()
	weapon_kills = s["weapon_kills"].duplicate()
	var c: Dictionary = s["carry"].duplicate()
	if not c.is_empty():
		c["weapons"] = c["weapons"].map(_gear_in)
		c["skills"] = c["skills"].map(_gear_in)
		for k in ["hp", "flasks", "max_flasks", "essence", "kills", "gold"]:
			c[k] = int(c.get(k, 0))
		for k in ["furia", "astucia", "vigor"]:
			c["levels"][k] = int(c["levels"].get(k, 0))
	carry = c


func suspend() -> void:
	Meta.data["suspended"] = snapshot()
	Meta.save()


func discard_saved() -> void:
	if Meta.data.has("suspended"):
		Meta.data.erase("suspended")
		Meta.save()


static func saved() -> Dictionary:
	return Meta.data.get("suspended", {})


func _gear_out(g: Variant) -> Variant:
	if g == null:
		return null
	return {"id": g.data.id, "tier": g.tier, "affixes": Array(g.affixes)}


func _gear_in(d: Variant) -> Variant:
	if d == null:
		return null
	var res := Catalog.find(String(d["id"]))
	if res == null:
		return null
	var g := Gear.of(res, int(d["tier"]))
	g.affixes.assign(d.get("affixes", []))
	return g


# --- desafio do dia ------------------------------------------------------------------
# Mesma semente para qualquer um no mesmo dia: dá para comparar com os amigos.

static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


static func daily_seed(date: String) -> int:
	return absi(hash("legado-" + date)) % 2147483647


func new_daily() -> void:
	var date := today()
	new_run(daily_seed(date), 0)
	daily = date


func note_hurt(who: String, amount: int) -> void:
	hurt_by[who] = int(hurt_by.get(who, 0)) + amount


func note_kill(enemy_title: String, weapon_id: String) -> void:
	kills_by[enemy_title] = int(kills_by.get(enemy_title, 0)) + 1
	if weapon_id != "":
		weapon_kills[weapon_id] = int(weapon_kills.get(weapon_id, 0)) + 1
