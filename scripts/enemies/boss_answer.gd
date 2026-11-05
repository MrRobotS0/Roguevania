class_name BossAnswer
extends Boss

# O que responde: Alguém ouviu as preces. não era o deus.


func _init() -> void:
	title = "O QUE RESPONDE"
	subtitle = "ALGUÉM OUVIU AS PRECES. NÃO ERA O DEUS"
	defeat_text = "O ALTAR FICOU EM SILÊNCIO. FINALMENTE"
	sheet = "boss_answer"
	max_hp = 1600
	hp = 1600
	w = 30
	h = 40
	weight = 5.0
	walk_speed = 60.0
	keep_distance = 120.0
	sounds = {"volley": "glyph", "rain": "curse"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "volley", "windup": 0.6, "style": "orb", "count": 3, "spread": 0.3, "speed": 160.0, "homing": 1.6, "damage": 16.0, "color": Color("6ae88a")},
		{"type": "rain", "windup": 0.6, "style": "water", "count": 4, "height": 70.0, "predict": true, "damage": 18.0},
		{"type": "beam", "windup": 0.8, "damage": 22.0},
	]
	moves2 = [
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/drowned.gd", "count": 2},
		{"type": "teleport", "reach": 60.0, "damage": 22.0},
	]


const REPLY := {"type": "volley", "windup": 0.3, "style": "orb", "count": 14, "radial": true, "speed": 165.0, "damage": 14.0, "recover": 0.3, "color": Color("6ae88a")}

var _hits := 0
var _owed := false
var _player_hp := -1


# Ele responde. Quem bate sem parar (6 golpes) ou bebe o frasco na frente dele leva
# uma resposta em todas as direções. O exausto continua sendo a sua janela.
func hurt(d: Damage) -> bool:
	var hit := super.hurt(d)
	if hit and not d.over_time:
		_hits += 1
		if _hits >= 6:
			_hits = 0
			_owed = true
	return hit


func think(delta: float) -> void:
	if _player_hp >= 0 and player.hp > _player_hp + 5:
		_owed = true
	_player_hp = player.hp
	if _owed and state in ["idle", "chase", "recover"]:
		_owed = false
		_move = REPLY
		_hit_done = false
		_shots = 0
		_clock = 0.0
		face_player()
		Fx.toast("ELE RESPONDE")
		Sfx.play("omen", -2.0)
		set_state("windup")
		return
	super.think(delta)
