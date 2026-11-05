class_name BossFox
extends Boss

# A raposa de nove caudas: O deus que caminhava seguia ela. ela só anda em círculos.


func _init() -> void:
	title = "A RAPOSA DE NOVE CAUDAS"
	subtitle = "O DEUS QUE CAMINHAVA SEGUIA ELA. ELA SÓ ANDA EM CÍRCULOS"
	defeat_text = "AS NOVE CAUDAS SE APAGARAM. A ESTRADA TERMINA AQUI"
	sheet = "boss_fox"
	max_hp = 2000
	hp = 2000
	w = 40
	h = 40
	weight = 5.0
	walk_speed = 110.0
	keep_distance = 0.0
	sounds = {"volley": "spirit_call", "charge": "wolf_bite"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "custom", "windup": 0.4, "recover": 0.5},
		{"type": "charge", "windup": 0.4, "speed": 480.0, "time": 0.55, "damage": 22.0},
		{"type": "volley", "windup": 0.5, "style": "orb", "count": 9, "radial": true, "speed": 160.0, "damage": 14.0, "color": Color("9fd8ff")},
		{"type": "leap", "windup": 0.45, "radius": 60.0, "damage": 22.0},
		{"type": "teleport", "reach": 56.0, "damage": 20.0},
	]
	moves2 = [
		{"type": "volley", "windup": 0.5, "style": "orb", "count": 3, "spread": 0.4, "speed": 140.0, "homing": 2.2, "damage": 15.0, "color": Color("9fd8ff")},
		{"type": "rain", "windup": 0.6, "style": "vine", "count": 4, "height": 44.0, "predict": true, "damage": 18.0},
	]


const DASH := 420.0
const WAIT := 0.55

var _tails := 9
var _dash_hit := false
var _appeared := false


# Nove caudas: cada nona parte da vida perdida apaga uma, e a cauda vira fogo que persegue.
func hurt(d: Damage) -> bool:
	var hit := super.hurt(d)
	if hit and alive():
		var left := ceili(float(hp) / max_hp * 9.0)
		while _tails > left:
			_tails -= 1
			shoot("orb", center() + Vector2(0, -14), Vector2.from_angle(randf_range(-2.4, -0.7)) * 130.0, 12.0, Color("9fd8ff"), 0.0, 2.4, 3.0)
	return hit


# Ilusões: some e volta em três, duas falsas (piscam; um golpe desfaz) e ela. Correm juntas.
func custom_start(_m: Dictionary) -> void:
	_dash_hit = false
	_appeared = false
	velocity = Vector2.ZERO
	Sfx.play("teleport", -2.0)


func _spot(side: float) -> float:
	return clampf(player.global_position.x + side, arena.position.x + w, arena.end.x - w)


func custom_update(_m: Dictionary, _delta: float) -> bool:
	if state_time < 0.25:
		velocity.x = 0.0
		_alpha = 1.0 - state_time / 0.25
		return false
	if not _appeared:
		_appeared = true
		var spots: Array[float] = [-130.0, 130.0, -190.0 if randf() < 0.5 else 190.0]
		spots.shuffle()
		global_position.x = _spot(spots[0])
		for i in [1, 2]:
			var copy := FoxIllusion.new()
			copy.room = room
			copy.player = player
			copy.position = Vector2(_spot(spots[i]), global_position.y)
			get_parent().add_child(copy)
		_alpha = 1.0
		face_player()
		return false
	if state_time < 0.25 + WAIT:
		velocity.x = 0.0
		face_player()
		return false
	velocity.x = 0.0 if blocked(facing) else facing * DASH
	if not _dash_hit:
		_dash_hit = strike(front_rect(20.0, h * 0.8, 0.0), 22.0, 260.0)
	if state_time >= 0.25 + WAIT + 0.6 or blocked(facing):
		velocity.x = 0.0
		return true
	return false


func custom_abort() -> void:
	_alpha = 1.0
