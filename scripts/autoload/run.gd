extends Node

# A partida atual: em que fase está, a semente do mapa e o que o herói
# carrega de uma fase para a outra. Morreu, acabou: tudo daqui é perdido
# (o que fica é o Meta).

# Rota da demonstração: o bioma gerado e depois a sala do chefe.
const ROUTE := [
	{"biome": "mar_de_cinzas", "kind": "gerada"},
	{"biome": "mar_de_cinzas", "kind": "chefe"},
]

var seed_value := 0
var stage := 0
var carry := {}
var time := 0.0
var active := false


func new_run(seed_override := -1) -> void:
	seed_value = seed_override if seed_override >= 0 else randi()
	stage = 0
	carry = {}
	time = 0.0
	active = true


func current() -> Dictionary:
	return ROUTE[stage]


func advance() -> bool:
	stage += 1
	return stage < ROUTE.size()


func _process(delta: float) -> void:
	if active and not get_tree().paused:
		time += delta


# Primeira fase: kit inicial + bênçãos compradas.
func starter_kit(p: Player) -> void:
	p.weapons = [Gear.of(load("res://content/weapons/espada_cerimonial.tres")),
		Gear.of(load("res://content/weapons/arco_dunas.tres"))]
	p.skills = [Gear.of(load("res://content/skills/granada_cinzas.tres")), null]
	var flasks := Player.BASE_FLASKS
	if Meta.is_unlocked("calice_1"):
		flasks += 1
	if Meta.is_unlocked("calice_2"):
		flasks += 1
	p.max_flasks = flasks
	p.flasks = flasks
	if Meta.is_unlocked("bencao_vigia"):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		p.levels[Combat.STATS[rng.randi_range(0, 2)]] += 1
	p.recompute_max_hp()
	p.hp = p.max_hp


func save_player(p: Player) -> void:
	carry = {
		"hp": p.hp, "weapons": p.weapons.duplicate(), "skills": p.skills.duplicate(),
		"levels": p.levels.duplicate(), "flasks": p.flasks, "max_flasks": p.max_flasks,
		"essence": p.essence, "kills": p.kills,
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
	p.recompute_max_hp()
	p.hp = clampi(carry["hp"], 1, p.max_hp)
