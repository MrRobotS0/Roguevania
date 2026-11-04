class_name WeaponData
extends Resource

# Uma arma é só dados: criar arma nova = escrever um .tres em content/weapons.
#
# category "melee": cada item de `moves` é um golpe do combo:
#   startup/active/recover (s), damage, knock, reach (Vector2), lunge,
#   stop (hitstop), shake, shape ("down", "up", "thrust", "smash"),
#   crit (true = esse golpe é sempre crítico), status ({"burn": 3.0})
# category "bow": `shot` = {draw, recover, speed, damage, pierce, status}
#
# crit_rule: crítico extra por situação
#   "behind" pelas costas · "burning" alvo queimando · "far" de longe
#   "stunned" alvo atordoado · "airborne" atacando no ar
#   "tip" acertando com a ponta (longe do corpo)
# shot também aceita: count + spread (vários de uma vez), style e homing
# (o que sai e se persegue), look ("crossbow", "staff") para o desenho

@export var id := ""
@export var title := ""
@export var category := "melee"
@export var stat := "furia"
@export var crit_rule := ""
@export var crit_mult := 1.75
@export var moves: Array = []
@export var shot: Dictionary = {}
@export var color := Color("d9e2ec")
@export var starter := false
@export var unlock_cost := 0
@export_multiline var lore := ""


func describe() -> String:
	var rule: String = {
		"behind": "CRÍTICO PELAS COSTAS",
		"burning": "CRÍTICO EM ALVO QUEIMANDO",
		"far": "CRÍTICO DE LONGE",
		"stunned": "CRÍTICO EM ALVO ATORDOADO",
		"airborne": "CRÍTICO NO AR",
		"tip": "CRÍTICO COM A PONTA",
	}.get(crit_rule, "")
	var last := ""
	for m: Dictionary in moves:
		if m.get("crit", false):
			last = "ÚLTIMO GOLPE CRÍTICO"
		if m.get("shape", "") == "spin":
			last = "ACERTA DOS DOIS LADOS"
	if int(shot.get("count", 1)) > 1:
		last = "%d DE UMA VEZ" % int(shot["count"])
	elif float(shot.get("homing", 0.0)) > 0.0:
		last = "PROCURA O ALVO"
	var parts := PackedStringArray()
	for part in [last, rule]:
		if part != "":
			parts.append(part)
	return " · ".join(parts)
