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
	"beira": {"biome": "mar_de_cinzas", "kind": "beira", "next": ["mar_de_cinzas"]},
	"ondas": {"biome": "mar_de_cinzas", "kind": "ondas", "next": []},
}
# Modo Waves: de 10 em 10 waves muda o domínio, na mesma ordem de dificuldade da rota.
const WAVE_ROUTE := [
	["saloes", "forja_rubra", "necropole"],
	["torre_babel", "jardim_primordial", "catedral"],
	["carcosa", "observatorio", "ventre"],
	["penhascos", "cavernas", "bosque"],
	["mar_de_cinzas"],
]
const WAVES := "ondas"
const FLASK_USES := 2      # no Modo Waves, cada frasco serve duas vezes
# Desafio da Semana: duas destas por semana. Os pares em RULE_CLASHES não vêm juntos.
const RULES := [
	{"id": "vidro", "title": "Vidro", "detail": "VOCÊ CAUSA O DOBRO DE DANO E LEVA O DOBRO"},
	{"id": "cacada", "title": "Caçada", "detail": "UM EM CADA QUATRO INIMIGOS VEM COMO ELITE"},
	{"id": "horda", "title": "Horda", "detail": "CADA INIMIGO VEM EM DOBRO, COM 60% DA VIDA"},
	{"id": "seca", "title": "Seca", "detail": "SEM FRASCOS, MAS COM O DOBRO DE VIDA"},
	{"id": "lua", "title": "Lua", "detail": "A GRAVIDADE CAI PARA 60%"},
	{"id": "vampiro", "title": "Vampiro", "detail": "CADA ABATE CURA 4 DE VIDA, MAS OS FRASCOS CURAM METADE"},
	{"id": "arsenal", "title": "Arsenal", "detail": "VOCÊ COMEÇA COM DUAS ARMAS SORTEADAS"},
	{"id": "mutante", "title": "Mutante", "detail": "VOCÊ COMEÇA COM TRÊS MUTAÇÕES SORTEADAS"},
	{"id": "fortuna", "title": "Fortuna", "detail": "OURO EM DOBRO, MAS INIMIGOS COM +30% DE VIDA"},
	{"id": "brasa", "title": "Brasa", "detail": "TODO GOLPE QUE VOCÊ LEVA QUEIMA, MAS VOCÊ CAUSA +30% DE DANO"},
]
const RULE_CLASHES := [["seca", "vampiro"], ["horda", "cacada"], ["vidro", "brasa"]]
const FIRST := "mar_de_cinzas"
const HALL := "sala_dos_treze"
const BEIRA := "beira"
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
var start_mutation := ""   # escolhida no poço da Beira
var advantage := ""        # escolhida na carroça da Beira
var revived := false       # a vantagem Cinza que Volta já foi usada
var mode := ""             # "" = partida normal; "ondas" = Modo Waves
var wave := 0              # em que wave está
var wave_block := 0        # quantos blocos de 10 waves já passaram
var wave_left := 0         # quantos faltam derrotar nesta wave
var week := ""             # semana do desafio ("" = não é o desafio da semana)
var rules: Array = []      # regras do desafio da semana


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
	start_mutation = ""
	advantage = ""
	revived = false
	mode = ""
	wave = 0
	wave_block = 0
	wave_left = 0
	week = ""
	rules = []
	active = true


# A Beira: o herói já está de pé, com o que escolheu, mas a partida não começou:
# sem relógio, sem caminho, sem nada salvo. Quem a atravessa chama depart().
func enter_beira() -> void:
	var cycle := clampi(int(Meta.data.get("pick_plus", 0)), 0, int(Meta.data.get("plus", 0)))
	var embers := clampi(int(Meta.data.get("pick_heat", 0)), 0, int(Meta.data["heat"]))
	new_run(-1, MAX_HEAT if cycle > 0 else embers, cycle)
	stage_id = BEIRA
	path = []
	active = false
	var mutation := String(Meta.data.get("pick_mutation", ""))
	start_mutation = mutation if Meta.start_mutations().has(mutation) else ""
	var pick := String(Meta.data.get("pick_advantage", ""))
	advantage = pick if Meta.has_advantage(pick) else ""


func depart() -> void:
	stage_id = FIRST
	path = [FIRST]
	carry = {}
	time = 0.0
	stage_time = 0.0
	active = true


func current() -> Dictionary:
	var s: Dictionary = STAGES[stage_id].duplicate()
	s["id"] = stage_id
	if in_passage:
		s["kind"] = "passagem"
	if stage_id == WAVES:
		s["biome"] = wave_biome(wave_block)
	return s


func next_options() -> Array:
	return STAGES[stage_id].get("next", [])


func boss_of(id: String) -> String:
	return STAGES[id].get("boss", "")


func stage_seed() -> int:
	return seed_value + (path.size() + wave_block) * 7349


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
	var mult := (1.0 + 0.4 * heat) * (1.0 + 0.2 * stage_tier) * plus_hp_mult()
	if mode == WAVES:
		mult *= 1.0 + 0.04 * wave
	if has_rule("horda"):
		mult *= 0.6
	if has_rule("fortuna"):
		mult *= 1.3
	return mult


# Chefes não crescem com o andar; no Modo Waves, crescem a cada bloco.
func guardian_mult() -> float:
	return 1.0 + 0.15 * wave_block if mode == WAVES else 1.0


func enemy_damage_mult() -> float:
	var mult := (1.0 + 0.25 * heat) * (1.0 + 0.1 * stage_tier) * (1.0 + 0.15 * plus)
	if mode == WAVES:
		mult *= 1.0 + 0.015 * wave
	if has_rule("vidro"):
		mult *= 2.0
	return mult


func hero_damage_mult() -> float:
	if has_rule("vidro"):
		return 2.0
	return 1.3 if has_rule("brasa") else 1.0


func plus_hp_mult() -> float:
	return 1.0 + 0.25 * plus


# Novo Jogo+: os pesadelos rendem mais essência, e alguns vêm como elite.
func essence_mult() -> float:
	return (1.0 + 0.5 * mini(plus, 1)) * (1.25 if advantage == "olho_coletor" else 1.0)


func plus_elite_chance() -> float:
	if has_rule("cacada"):
		return 0.25
	return 0.09 + 0.03 * plus if plus > 0 else 0.0


func has_rule(id: String) -> bool:
	return rules.has(id)


func gravity_mult() -> float:
	return 0.6 if has_rule("lua") else 1.0


func max_hp_mult() -> float:
	return 2.0 if has_rule("seca") else 1.0


func flask_heal_mult() -> float:
	return 0.5 if has_rule("vampiro") else 1.0


# Quanto vale "ganhar um frasco" nas regras atuais.
func flask_gain() -> int:
	if has_rule("seca"):
		return 0
	return FLASK_USES if mode == WAVES else 1


func flasks_for_sale() -> bool:
	return mode != WAVES and not has_rule("seca")


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
	# no Modo Waves o primeiro frasco é o da wave 5
	if mode == WAVES or has_rule("seca"):
		p.max_flasks = 0
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
	_apply_advantage(p)
	if start_mutation != "":
		p.add_mutation(start_mutation)
	_apply_rules(p)
	p.recompute_max_hp()
	p.hp = p.max_hp


func _apply_advantage(p: Player) -> void:
	match advantage:
		"saco_moedas":
			p.gold += 80
		"frasco_reserva":
			p.max_flasks += 1
			p.flasks = p.max_flasks
		"lamina_afiada":
			p.weapons = [Gear.of(p.weapons[0].data, p.weapons[0].tier + 1), Gear.of(p.weapons[1].data, p.weapons[1].tier + 1)]
		"bolso_fundo":
			var pool: Array[Resource] = Catalog.unlocked_pool().filter(func(r: Resource) -> bool:
				return r is SkillData and r != p.skills[0].data)
			if not pool.is_empty():
				var rng := RandomNumberGenerator.new()
				rng.seed = seed_value + 3
				p.skills[1] = Gear.of(pool[rng.randi_range(0, pool.size() - 1)])


func _apply_rules(p: Player) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 11
	if has_rule("arsenal"):
		var pool: Array[Resource] = Catalog.all_gear().filter(func(r: Resource) -> bool: return r is WeaponData)
		var first := rng.randi_range(0, pool.size() - 1)
		var second := (first + rng.randi_range(1, pool.size() - 1)) % pool.size()
		p.weapons = [Gear.of(pool[first]), Gear.of(pool[second])]
	if has_rule("mutante"):
		var ids: Array = Catalog.MUTATIONS.map(func(m: Dictionary) -> String: return String(m["id"]))
		for i in Catalog.MAX_MUTATIONS:
			p.add_mutation(ids.pop_at(rng.randi_range(0, ids.size() - 1)))


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
		"weapon_kills": weapon_kills.duplicate(), "carry": c, "plus": plus,
		"start_mutation": start_mutation, "advantage": advantage, "revived": revived,
		"mode": mode, "wave_block": wave_block, "week": week}


func restore(s: Dictionary) -> void:
	new_run(int(s["seed"]), int(s["heat"]), int(s.get("plus", 0)))
	stage_id = s["stage"]
	in_passage = s["in_passage"]
	path.assign(s["path"])
	time = float(s["time"])
	daily = s["daily"]
	start_mutation = String(s.get("start_mutation", ""))
	advantage = String(s.get("advantage", ""))
	revived = bool(s.get("revived", false))
	mode = String(s.get("mode", ""))
	wave_block = int(s.get("wave_block", 0))
	wave = wave_block * WaveDirector.PER_BLOCK
	week = String(s.get("week", ""))
	rules = week_rules(week) if week != "" else []
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


# --- desafio da semana --------------------------------------------------------------
# A semana vira na segunda-feira. Mesmo mapa e mesmas regras para todos até lá.

static func this_week() -> String:
	var unix := Time.get_unix_time_from_datetime_dict(Time.get_date_dict_from_system())
	return "S%d" % floori((unix + 3 * 86400) / (7.0 * 86400))


static func week_rules(id: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("semana-" + id)
	var ids: Array = RULES.map(func(r: Dictionary) -> String: return String(r["id"]))
	var first: String = ids.pop_at(rng.randi_range(0, ids.size() - 1))
	var fits := ids.filter(func(other: String) -> bool:
		return not RULE_CLASHES.any(func(c: Array) -> bool: return c.has(first) and c.has(other)))
	return [first, fits[rng.randi_range(0, fits.size() - 1)]]


static func rule(id: String) -> Dictionary:
	for r: Dictionary in RULES:
		if r["id"] == id:
			return r
	return {}


func new_weekly() -> void:
	var id := this_week()
	new_run(absi(hash("semana-mapa-" + id)) % 2147483647, 0)
	week = id
	rules = week_rules(id)


# --- Modo Waves ------------------------------------------------------------------------

func new_waves() -> void:
	new_run()
	stage_id = WAVES
	path = [WAVES]
	mode = WAVES


func wave_biome(block: int) -> String:
	var group: Array = WAVE_ROUTE[block % WAVE_ROUTE.size()]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + block
	return group[rng.randi_range(0, group.size() - 1)]


func next_block() -> void:
	wave_block += 1
	stage_time = 0.0


func note_hurt(who: String, amount: int) -> void:
	hurt_by[who] = int(hurt_by.get(who, 0)) + amount


func note_kill(enemy_title: String, weapon_id: String) -> void:
	kills_by[enemy_title] = int(kills_by.get(enemy_title, 0)) + 1
	if weapon_id != "":
		weapon_kills[weapon_id] = int(weapon_kills.get(weapon_id, 0)) + 1
