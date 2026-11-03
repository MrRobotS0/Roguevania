class_name BiomeData
extends Resource

# Tudo que faz um bioma ser ele mesmo. Os sistemas (combate, gerador,
# câmera, HUD) não conhecem nenhum bioma: leem isto.

@export var id := ""
@export var title := ""
@export var subtitle := ""
@export var colors: Dictionary = {}        # mesmas chaves de Room.default_colors()
@export var sky: Dictionary = {}           # sky0, sky1, sky2, glow, sun, accent
@export var backdrop := "dunes"
@export var weather := ""
@export var rooms_dir := ""
@export var boss_room := ""
@export var combat_rooms := 6
@export var enemies: Array = []            # [{"script": "res://...", "slot": "e", "weight": 10}]
@export var elites: Array = []             # ["res://..."]
@export var boss_script := ""
@export var exits: Array = []              # [{"title": "...", "to": "id", "sealed": false}]
@export var lore: Array = []               # textos das inscrições, em ordem
@export var tier := 0


func pick_enemy(slot: String, rng: RandomNumberGenerator) -> String:
	var options: Array = []
	var total := 0
	for e: Dictionary in enemies:
		if e["slot"] == slot:
			options.append(e)
			total += int(e["weight"])
	if options.is_empty():
		return ""
	var roll := rng.randi_range(1, total)
	for e: Dictionary in options:
		roll -= int(e["weight"])
		if roll <= 0:
			return e["script"]
	return options[-1]["script"]


func room_colors() -> Dictionary:
	var out := Room.default_colors()
	for k in colors:
		out[k] = colors[k]
	return out
