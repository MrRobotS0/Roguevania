class_name BossDragon
extends Boss

# O dragão sonhado: O deus que sonhava sonhou um guarda. ele acordou.


func _init() -> void:
	title = "O DRAGÃO SONHADO"
	subtitle = "O DEUS QUE SONHAVA SONHOU UM GUARDA. ELE ACORDOU"
	defeat_text = "O SONHO ACABOU. O DRAGÃO NÃO ESTAVA MAIS LÁ"
	sheet = "boss_dragon"
	max_hp = 2000
	hp = 2000
	w = 50
	h = 46
	weight = 5.0
	walk_speed = 80.0
	keep_distance = 0.0
	sounds = {"volley": "roar", "charge": "roar"}
	essence_drop = Vector2i(80, 80)

	moves = [
		{"type": "custom", "windup": 0.5, "recover": 0.9},
		{"type": "volley", "windup": 0.6, "style": "orb", "count": 5, "spread": 0.35, "speed": 240.0, "damage": 18.0, "color": Color("c88aff")},
		{"type": "charge", "windup": 0.5, "speed": 440.0, "time": 0.7, "damage": 24.0},
		{"type": "melee", "windup": 0.45, "reach": 76.0, "height": 40.0, "damage": 24.0, "max_range": 100.0},
		{"type": "rain", "windup": 0.7, "style": "dream", "count": 4, "height": 80.0, "predict": true, "damage": 18.0},
	]
	moves2 = [
		{"type": "beam", "windup": 0.7, "damage": 24.0},
		{"type": "summon", "windup": 0.6, "script": "res://scripts/enemies/nightmare.gd", "count": 1},
	]


const DREAM_TIME := 1.7

var _next_rain := 0.0
var _dropped := false


# Some do mundo (ninguém acerta o que está dormindo), o chão se enche de sonho
# embaixo de você, e ele cai do alto onde você estava.
func custom_start(_m: Dictionary) -> void:
	_next_rain = 0.3
	_dropped = false
	uses_gravity = false
	velocity = Vector2.ZERO
	Sfx.play("teleport", -2.0)


func custom_update(_m: Dictionary, delta: float) -> bool:
	if not _dropped:
		velocity = Vector2.ZERO
		_alpha = 1.0 - clampf(state_time / 0.3, 0.0, 1.0)
		_next_rain -= delta
		if _next_rain <= 0.0 and state_time < DREAM_TIME - 0.3:
			_next_rain = 0.32 * _tm()
			var x := clampf(player.global_position.x + player.velocity.x * 0.3, arena.position.x + 16.0, arena.end.x - 16.0)
			make_hazard("dream", x, 0.6, 16.0, 26.0, 74.0)
		if state_time >= DREAM_TIME:
			_dropped = true
			var ground := global_position.y
			var x := clampf(player.global_position.x, arena.position.x + w, arena.end.x - w)
			var lift := 110.0
			while lift > 0.0 and room.is_solid_at(Vector2(x, ground - lift - h)):
				lift -= 16.0
			global_position = Vector2(x, ground - maxf(lift, 0.0))
			make_hazard("dream", x, 0.25, 0.0, 70.0, 6.0, true).position.y = ground
			uses_gravity = true
			velocity = Vector2(0, 240.0)
			_alpha = 1.0
			face_player()
		return false
	if is_on_floor():
		velocity = Vector2.ZERO
		strike(Rect2(global_position.x - 74.0, global_position.y - 22.0, 148.0, 22.0), 26.0, 260.0)
		Fx.burst(global_position, Color("c88aff"), 26, 200.0, 0.5, 200.0, 3.0, 40.0)
		Fx.add_shake(6.0)
		Sfx.play("slam")
		return true
	return state_time > DREAM_TIME + 1.5


func custom_abort() -> void:
	uses_gravity = true
	_alpha = 1.0
